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

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
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
        rootObj.insert(entry.versionString, innerObj);
    }

    QFile file(target);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit statusMessageAlert("Could not open file descriptor for writing", false);
        return false;
    }

    QJsonDocument doc(rootObj);
    QTextStream outStream(&file);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
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

bool ChangeLogManager::appendVersionEntry(const QString &v, const QString &d, const QString &joinedChanges) {
    if (v.trimmed().isEmpty()) return false;

    LogVersionEntry entry;
    entry.versionString = v.trimmed();
    entry.dateString = d.trimmed();

    // Split the flattened string using a safe character boundary mapping (\n)
    entry.changeItems = joinedChanges.split("\n", QString::SkipEmptyParts);

    m_entries.append(entry);
    organizeEntriesByVersion();
    m_isDirty = true;

    emit entriesChanged();
    emit dirtyChanged();
    return true;
}

bool ChangeLogManager::commitVersionEntry(int targetIndex, const QString &v, const QString &d, const QString &joinedChanges) {
    if (targetIndex < 0 || targetIndex >= m_entries.size() || v.trimmed().isEmpty()) return false;

    m_entries[targetIndex].versionString = v.trimmed();
    m_entries[targetIndex].dateString = d.trimmed();
    m_entries[targetIndex].changeItems = joinedChanges.split("\n", QString::SkipEmptyParts);

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
