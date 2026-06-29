#include "ChangeLogManager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QDir>
#include <QUrl>
#include <QDateTime>
#include <QTextStream>
#include <QDebug>
#include <algorithm>
#include <QCoreApplication>
#include <QFileInfo>
#include <QCryptographicHash>
#include <QUuid>

ChangeLogManager::ChangeLogManager(QObject *parent) : QObject(parent) {}

QString ChangeLogManager::sanitizeUrlToNativePath(const QString &rawPath) const {
    if (rawPath.isEmpty()) return QString();
    QString clean = rawPath;
    if (clean.startsWith("file:///")) {
#ifdef Q_OS_WIN
        clean = clean.mid(8);
#else
        clean = clean.mid(7);
#endif
    } else if (clean.startsWith("file://")) {
        clean = clean.mid(7);
    }
    return QDir::toNativeSeparators(clean);
}

QString ChangeLogManager::getAssetDirectoryPath() const {
    QString uploadRoot = QCoreApplication::applicationDirPath() + "/upload";
    if (m_filePath.isEmpty()) {
        return uploadRoot + "/unsaved_workspace";
    }
    QString baseName = QFileInfo(m_filePath).baseName();
    QString pathHash = QString(QCryptographicHash::hash(m_filePath.toUtf8(), QCryptographicHash::Md5).toHex().left(6));
    return uploadRoot + "/" + baseName + "_" + pathHash;
}

void ChangeLogManager::resetWorkspace() {
    m_entries.clear();
    m_filePath.clear();
    m_isDirty = false;
    emit entriesChanged();
    emit filePathChanged();
    emit dirtyChanged();
}

QString ChangeLogManager::convertToJalali(const QString &gregorianDate) const {
    QStringList parts = gregorianDate.split('-');
    if (parts.size() != 3) return QString("----/--/--");

    int gy = parts[0].toInt();
    int gm = parts[1].toInt();
    int gd = parts[2].toInt();

    int gy_m = gy - 1600;
    int gm_m = gm - 1;
    int gd_m = gd - 1;

    long g_day_no = 365 * gy_m + (gy_m + 3) / 4 - (gy_m + 99) / 100 + (gy_m + 399) / 400;
    for (int i = 0; i < gm_m; ++i) {
        if (i == 1 && ((gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0))) {
            g_day_no += 29;
        } else {
            int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
            g_day_no += days[i];
        }
    }
    g_day_no += gd_m;

    long j_day_no = g_day_no - 79;
    long j_np = j_day_no / 12053;
    j_day_no %= 12053;

    long jy = 979 + 33 * j_np + 4 * (j_day_no / 1461);
    j_day_no %= 1461;

    if (j_day_no >= 366) {
        jy += (j_day_no - 1) / 365;
        j_day_no = (j_day_no - 1) % 365;
    }

    int jm = 0;
    int j_days_in_month[] = {31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29};
    for (int i = 0; i < 12; ++i) {
        if (j_day_no < j_days_in_month[i]) {
            jm = i + 1;
            break;
        }
        j_day_no -= j_days_in_month[i];
    }
    int jd = j_day_no + 1;

    return QString("%1/%2/%3")
        .arg(jy)
        .arg(jm, 2, 10, QChar('0'))
        .arg(jd, 2, 10, QChar('0'));
}

bool ChangeLogManager::loadFromFile(const QString &rawPath) {
    QString target = sanitizeUrlToNativePath(rawPath);
    if (target.isEmpty()) return false;

    QFile file(target);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit statusMessageAlert("Failed to open file for reading", false);
        return false;
    }

    QTextStream inStream(&file);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    inStream.setEncoding(QStringConverter::Utf8);
#else
    inStream.setCodec("UTF-8");
#endif

    QString fileContent = inStream.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(fileContent.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        emit statusMessageAlert("Invalid JSON format detected", false);
        return false;
    }

    m_entries.clear();
    QJsonObject rootObj = doc.object();

    for (auto it = rootObj.begin(); it != rootObj.end(); ++it) {
        LogVersionEntry entry;
        entry.versionString = it.key();

        QJsonObject innerObj = it.value().toObject();
        entry.dateString = innerObj.value("date").toString();

        QJsonArray changesArr = innerObj.value("changes").toArray();
        for (const QJsonValue &val : changesArr) {
            ChangeItem cItem;
            if (val.isObject()) {
                QJsonObject cObj = val.toObject();
                cItem.text = cObj.value("text").toString();
                QJsonArray cImgs = cObj.value("images").toArray();
                for (const QJsonValue &imgVal : cImgs) {
                    cItem.imagePaths.append(imgVal.toString());
                }
            } else {
                cItem.text = val.toString(); // Fallback backward compatibility layer
            }
            entry.changeItems.append(cItem);
        }

        QJsonArray imagesArr = innerObj.value("images").toArray();
        for (const QJsonValue &val : imagesArr) {
            entry.imagePaths.append(val.toString());
        }
        m_entries.append(entry);
    }

    organizeEntriesByVersion();
    m_filePath = target;
    m_isDirty = false;

    cleanOrphanedImages();

    emit entriesChanged();
    emit filePathChanged();
    emit dirtyChanged();
    emit statusMessageAlert("Changelog loaded successfully", true);
    return true;
}

bool ChangeLogManager::saveToFile() {
    return saveAsFile(m_filePath);
}

bool ChangeLogManager::saveAsFile(const QString &rawPath) {
    QString target = sanitizeUrlToNativePath(rawPath);
    if (target.isEmpty()) {
        emit statusMessageAlert("Target write path is empty", false);
        return false;
    }

    QString oldFilePath = m_filePath;
    m_filePath = target;
    QString newAssetDir = QFileInfo(getAssetDirectoryPath()).absoluteFilePath();
    m_filePath = oldFilePath;

    QDir(newAssetDir).mkpath(".");

    // ASSET MIGRATION ENGINE (Now deeply tracks both Version and Child-Description layers)
    for (int i = 0; i < m_entries.size(); ++i) {
        // Core Version Image Array Migration
        for (int j = 0; j < m_entries[i].imagePaths.size(); ++j) {
            QString currentUrl = m_entries[i].imagePaths[j];
            QString currentNativePath = sanitizeUrlToNativePath(currentUrl);
            if (QDir::isRelativePath(currentNativePath)) currentNativePath = QCoreApplication::applicationDirPath() + "/" + currentNativePath;

            QFileInfo fileInfo(currentNativePath);
            QString absFilePath = fileInfo.absoluteFilePath();

            if (QFile::exists(absFilePath) && !absFilePath.startsWith(newAssetDir)) {
                QString destinationPath = newAssetDir + "/" + fileInfo.fileName();
                if (!QFile::exists(destinationPath)) QFile::copy(absFilePath, destinationPath);
                m_entries[i].imagePaths[j] = "file:///" + QDir::toNativeSeparators(destinationPath);
            }
        }

        // Deep Child-Description Image Array Migration
        for (int j = 0; j < m_entries[i].changeItems.size(); ++j) {
            for (int k = 0; k < m_entries[i].changeItems[j].imagePaths.size(); ++k) {
                QString currentUrl = m_entries[i].changeItems[j].imagePaths[k];
                QString currentNativePath = sanitizeUrlToNativePath(currentUrl);
                if (QDir::isRelativePath(currentNativePath)) currentNativePath = QCoreApplication::applicationDirPath() + "/" + currentNativePath;

                QFileInfo fileInfo(currentNativePath);
                QString absFilePath = fileInfo.absoluteFilePath();

                if (QFile::exists(absFilePath) && !absFilePath.startsWith(newAssetDir)) {
                    QString destinationPath = newAssetDir + "/" + fileInfo.fileName();
                    if (!QFile::exists(destinationPath)) QFile::copy(absFilePath, destinationPath);
                    m_entries[i].changeItems[j].imagePaths[k] = "file:///" + QDir::toNativeSeparators(destinationPath);
                }
            }
        }
    }

    if (oldFilePath.isEmpty()) {
        QString tempUnsavedFolder = QFileInfo(QCoreApplication::applicationDirPath() + "/upload/unsaved_workspace").absoluteFilePath();
        QDir(tempUnsavedFolder).removeRecursively();
    }

    m_filePath = target;

    QJsonObject rootObj;
    for (const LogVersionEntry &entry : m_entries) {
        QJsonObject innerObj;
        innerObj.insert("date", entry.dateString);

        QJsonArray changesArr;
        for (const ChangeItem &item : entry.changeItems) {
            QJsonObject changeObj;
            changeObj.insert("text", item.text);
            QJsonArray subImgs;
            for (const QString &imgUrl : item.imagePaths) {
                subImgs.append(imgUrl);
            }
            changeObj.insert("images", subImgs);
            changesArr.append(changeObj);
        }
        innerObj.insert("changes", changesArr);

        QJsonArray imagesArr;
        for (const QString &imgUrl : entry.imagePaths) {
            imagesArr.append(imgUrl);
        }
        innerObj.insert("images", imagesArr);

        rootObj.insert(entry.versionString, innerObj);
    }

    QFile file(target);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit statusMessageAlert("Could not open file descriptor for writing", false);
        return false;
    }

    QJsonDocument doc(rootObj);
    QTextStream outStream(&file);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    outStream.setEncoding(QStringConverter::Utf8);
#else
    outStream.setCodec("UTF-8");
#endif

    outStream << doc.toJson(QJsonDocument::Indented);
    outStream.flush();
    file.close();

    m_isDirty = false;
    cleanOrphanedImages();

    emit filePathChanged();
    emit dirtyChanged();
    emit statusMessageAlert("File written securely to disk", true);
    return true;
}

bool ChangeLogManager::appendVersionEntry(const QString &v, const QString &d, const QVariantList &changesList, const QString &joinedImages) {
    if (v.trimmed().isEmpty()) return false;

    LogVersionEntry entry;
    entry.versionString = v.trimmed();
    entry.dateString = d.trimmed();

    for (const QVariant &val : changesList) {
        ChangeItem cItem;
        QVariantMap vMap = val.toMap();
        cItem.text = vMap.value("text").toString().trimmed();
        cItem.imagePaths = vMap.value("images").toStringList();
        entry.changeItems.append(cItem);
    }

#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    entry.imagePaths = joinedImages.split("\n", Qt::SkipEmptyParts);
#else
    entry.imagePaths = joinedImages.split("\n", QString::SkipEmptyParts);
#endif

    m_entries.append(entry);
    organizeEntriesByVersion();
    m_isDirty = true;

    emit entriesChanged();
    emit dirtyChanged();
    return true;
}

bool ChangeLogManager::commitVersionEntry(int targetIndex, const QString &v, const QString &d, const QVariantList &changesList, const QString &joinedImages) {
    if (targetIndex < 0 || targetIndex >= m_entries.size() || v.trimmed().isEmpty()) return false;

    m_entries[targetIndex].versionString = v.trimmed();
    m_entries[targetIndex].dateString = d.trimmed();
    m_entries[targetIndex].changeItems.clear();

    for (const QVariant &val : changesList) {
        ChangeItem cItem;
        QVariantMap vMap = val.toMap();
        cItem.text = vMap.value("text").toString().trimmed();
        cItem.imagePaths = vMap.value("images").toStringList();
        m_entries[targetIndex].changeItems.append(cItem);
    }

#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    m_entries[targetIndex].imagePaths = joinedImages.split("\n", Qt::SkipEmptyParts);
#else
    m_entries[targetIndex].imagePaths = joinedImages.split("\n", QString::SkipEmptyParts);
#endif

    organizeEntriesByVersion();
    m_isDirty = true;

    emit entriesChanged();
    emit dirtyChanged();
    return true;
}

void ChangeLogManager::removeVersionEntry(int index) {
    if (index >= 0 && index < m_entries.size()) {
        m_entries.removeAt(index);
        m_isDirty = true;
        emit entriesChanged();
        emit dirtyChanged();
    }
}

QVariantList ChangeLogManager::fetchSerializedEntries() const {
    QVariantList list;
    for (const LogVersionEntry &entry : m_entries) {
        QVariantMap map;
        map.insert("version", entry.versionString);
        map.insert("date", entry.dateString);

        QVariantList changesList;
        for (const ChangeItem &cItem : entry.changeItems) {
            QVariantMap cMap;
            cMap.insert("text", cItem.text);
            cMap.insert("images", cItem.imagePaths);
            changesList.append(cMap);
        }
        map.insert("changes", changesList);
        map.insert("images", entry.imagePaths);
        list.append(map);
    }
    return list;
}

QString ChangeLogManager::fetchVersionName(int index) const {
    return (index >= 0 && index < m_entries.size()) ? m_entries[index].versionString : "";
}

QString ChangeLogManager::fetchVersionDate(int index) const {
    return (index >= 0 && index < m_entries.size()) ? m_entries[index].dateString : "";
}

QVariantList ChangeLogManager::fetchVersionChangesList(int index) const {
    QVariantList list;
    if (index >= 0 && index < m_entries.size()) {
        for (const ChangeItem &item : m_entries[index].changeItems) {
            QVariantMap map;
            map.insert("text", item.text);
            map.insert("images", item.imagePaths);
            list.append(map);
        }
    }
    return list;
}

QString ChangeLogManager::fetchVersionImagesJoined(int index) const {
    return (index >= 0 && index < m_entries.size()) ? m_entries[index].imagePaths.join("\n") : "";
}

QString ChangeLogManager::getSystemDateString() const {
    return QDateTime::currentDateTime().toString("yyyy-MM-dd");
}

void ChangeLogManager::organizeEntriesByVersion() {
    std::sort(m_entries.begin(), m_entries.end(), [](const LogVersionEntry &a, const LogVersionEntry &b) {
        QStringList tokensA = a.versionString.split('.');
        QStringList tokensB = b.versionString.split('.');
        int balance = qMax(tokensA.size(), tokensB.size());
        for (int i = 0; i < balance; ++i) {
            int valA = (i < tokensA.size()) ? tokensA[i].toInt() : 0;
            int valB = (i < tokensB.size()) ? tokensB[i].toInt() : 0;
            if (valA != valB) return valA > valB;
        }
        return false;
    });
}

QString ChangeLogManager::copyImageToUploads(const QString &sourceUrl) {
    QString srcPath = sanitizeUrlToNativePath(sourceUrl);
    if (srcPath.isEmpty() || !QFile::exists(srcPath)) {
        emit statusMessageAlert("Source image file does not exist", false);
        return QString();
    }

    QString uploadDirPath = getAssetDirectoryPath();
    QDir uploadDir(uploadDirPath);
    if (!uploadDir.exists()) uploadDir.mkpath(".");

    QFileInfo fileInfo(srcPath);
    QString uniqueId = QUuid::createUuid().toString(QUuid::Id128).left(8);
    QString uniqueName = uniqueId + "_" + fileInfo.fileName();
    QString targetFilePath = uploadDirPath + "/" + uniqueName;

    if (QFile::copy(srcPath, targetFilePath)) {
        return "file:///" + targetFilePath;
    } else {
        emit statusMessageAlert("Failed to copy image to local upload folder", false);
        return QString();
    }
}

void ChangeLogManager::cleanOrphanedImages() {
    QStringList activePaths;
    for (const LogVersionEntry &entry : m_entries) {
        for (const QString &imgUrl : entry.imagePaths) {
            activePaths.append(QFileInfo(sanitizeUrlToNativePath(imgUrl)).absoluteFilePath());
        }
        for (const ChangeItem &cItem : entry.changeItems) {
            for (const QString &imgUrl : cItem.imagePaths) {
                activePaths.append(QFileInfo(sanitizeUrlToNativePath(imgUrl)).absoluteFilePath());
            }
        }
    }

    QString uploadDirPath = QFileInfo(getAssetDirectoryPath()).absoluteFilePath();
    QDir uploadDir(uploadDirPath);
    if (!uploadDir.exists()) return;

    QFileInfoList fileList = uploadDir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
    int deleteCount = 0;

    for (const QFileInfo &fileInfo : fileList) {
        QString physicalFilePath = fileInfo.absoluteFilePath();
        if (!activePaths.contains(physicalFilePath)) {
            QFile::remove(physicalFilePath);
            deleteCount++;
        }
    }
    if (deleteCount > 0) {
        qDebug() << "Garbage collection cleaned up" << deleteCount << "unreferenced images.";
    }
}
