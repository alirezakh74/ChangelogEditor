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

void ChangeLogManager::resetWorkspace() {
    m_entries.clear();
    m_filePath.clear();
    m_isDirty = false;
    emit entriesChanged();
    emit filePathChanged();
    emit dirtyChanged();
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
            entry.changeItems.append(val.toString());
        }

        // Parse images structural data back out cleanly
        QJsonArray imagesArr = innerObj.value("images").toArray();
        for (const QJsonValue &val : imagesArr) {
            entry.imagePaths.append(val.toString());
        }

        m_entries.append(entry);
    }

    organizeEntriesByVersion();
    m_filePath = target;
    m_isDirty = false;

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

    QJsonObject rootObj;
    for (const LogVersionEntry &entry : m_entries) {
        QJsonObject innerObj;
        innerObj.insert("date", entry.dateString);

        QJsonArray changesArr;
        for (const QString &item : entry.changeItems) {
            changesArr.append(item);
        }
        innerObj.insert("changes", changesArr);

        // Map attached images array into standard structural JSON schema
        QJsonArray imagesArr;
        for (const QString &img : entry.imagePaths) {
            imagesArr.append(img);
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

    m_filePath = target;
    m_isDirty = false;

    emit filePathChanged();
    emit dirtyChanged();
    emit statusMessageAlert("File written securely to disk", true);
    return true;
}

bool ChangeLogManager::appendVersionEntry(const QString &v, const QString &d, const QString &joinedChanges, const QString &joinedImages) {
    if (v.trimmed().isEmpty()) return false;

    LogVersionEntry entry;
    entry.versionString = v.trimmed();
    entry.dateString = d.trimmed();

#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    entry.changeItems = joinedChanges.split("\n", Qt::SkipEmptyParts);
    entry.imagePaths = joinedImages.split("\n", Qt::SkipEmptyParts);
#else
    entry.changeItems = joinedChanges.split("\n", QString::SkipEmptyParts);
    entry.imagePaths = joinedImages.split("\n", QString::SkipEmptyParts);
#endif

    m_entries.append(entry);
    organizeEntriesByVersion();
    m_isDirty = true;

    emit entriesChanged();
    emit dirtyChanged();
    return true;
}

bool ChangeLogManager::commitVersionEntry(int targetIndex, const QString &v, const QString &d, const QString &joinedChanges, const QString &joinedImages) {
    if (targetIndex < 0 || targetIndex >= m_entries.size() || v.trimmed().isEmpty()) return false;

    m_entries[targetIndex].versionString = v.trimmed();
    m_entries[targetIndex].dateString = d.trimmed();

#if QT_VERSION >= QT_VERSION_CHECK(5, 14, 0)
    m_entries[targetIndex].changeItems = joinedChanges.split("\n", Qt::SkipEmptyParts);
    m_entries[targetIndex].imagePaths = joinedImages.split("\n", Qt::SkipEmptyParts);
#else
    m_entries[targetIndex].changeItems = joinedChanges.split("\n", QString::SkipEmptyParts);
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
        map.insert("changes", entry.changeItems);
        map.insert("images", entry.imagePaths); // Pass through to high-level visualizers
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

QString ChangeLogManager::fetchVersionChangesJoined(int index) const {
    return (index >= 0 && index < m_entries.size()) ? m_entries[index].changeItems.join("\n") : "";
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

    QString uploadDirPath = QCoreApplication::applicationDirPath() + "/upload";
    QDir uploadDir(uploadDirPath);
    if (!uploadDir.exists()) {
        uploadDir.mkpath(".");
    }

    QFileInfo fileInfo(srcPath);
    QString uniqueName = QString::number(QDateTime::currentMSecsSinceEpoch())
                         + "_" + fileInfo.fileName();
    QString targetFilePath = uploadDirPath + "/" + uniqueName;

    if (QFile::copy(srcPath, targetFilePath)) {
        return "file:///" + targetFilePath;
    } else {
        emit statusMessageAlert("Failed to copy image to local upload folder", false);
        return QString();
    }
}

bool ChangeLogManager::deleteImageFromUploads(const QString &fileUrlOrPath) {
    if (fileUrlOrPath.isEmpty()) return false;

    // Convert potential file:// URLs or raw paths into clean native file system paths
    QString targetPath = sanitizeUrlToNativePath(fileUrlOrPath);

    // If the path was stored as relative to the application binary, resolve it absolutely
    if (QDir::isRelativePath(targetPath)) {
        targetPath = QCoreApplication::applicationDirPath() + "/" + targetPath;
    }

    QFileInfo fileInfo(targetPath);
    QString absoluteFilePath = fileInfo.absoluteFilePath();

    // Resolve the strict absolute canonical path of the uploads folder
    QString uploadDirPath = QFileInfo(QCoreApplication::applicationDirPath() + "/upload").absoluteFilePath();

    // Security boundary validation check: prevent directory traversal escapes
    if (!absoluteFilePath.startsWith(uploadDirPath)) {
        emit statusMessageAlert("Security sandbox rejection: Action aborted.", false);
        return false;
    }

    // Attempt physical file deletion if file exists on disk
    if (QFile::exists(absoluteFilePath)) {
        if (QFile::remove(absoluteFilePath)) {
            emit statusMessageAlert("Asset physically removed from disk.", true);
            return true;
        } else {
            emit statusMessageAlert("Failed to remove file asset from disk permissions.", false);
            return false;
        }
    }

    return false;
}
