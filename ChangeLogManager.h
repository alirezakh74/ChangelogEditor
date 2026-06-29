#ifndef CHANGELOGMANAGER_H
#define CHANGELOGMANAGER_H

#include <QObject>
#include <QList>
#include <QStringList>
#include <QVariantList>

struct LogVersionEntry {
    QString versionString;
    QString dateString;
    QStringList changeItems;
    QStringList imagePaths;
};

class ChangeLogManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentFilePath READ currentFilePath NOTIFY filePathChanged)
    Q_PROPERTY(int totalVersions READ totalVersions NOTIFY entriesChanged)
    Q_PROPERTY(bool isDirty READ isDirty NOTIFY dirtyChanged)

public:
    explicit ChangeLogManager(QObject *parent = nullptr);

    QString currentFilePath() const { return m_filePath; }
    int totalVersions() const { return m_entries.size(); }
    bool isDirty() const { return m_isDirty; }

    Q_INVOKABLE void resetWorkspace();
    Q_INVOKABLE bool loadFromFile(const QString &rawPath);
    Q_INVOKABLE bool saveToFile();
    Q_INVOKABLE bool saveAsFile(const QString &rawPath);

    Q_INVOKABLE bool commitVersionEntry(int targetIndex, const QString &v, const QString &d, const QString &joinedChanges, const QString &joinedImages);
    Q_INVOKABLE bool appendVersionEntry(const QString &v, const QString &d, const QString &joinedChanges, const QString &joinedImages);
    Q_INVOKABLE void removeVersionEntry(int index);

    Q_INVOKABLE QVariantList fetchSerializedEntries() const;
    Q_INVOKABLE QString fetchVersionName(int index) const;
    Q_INVOKABLE QString fetchVersionDate(int index) const;
    Q_INVOKABLE QString fetchVersionChangesJoined(int index) const;
    Q_INVOKABLE QString fetchVersionImagesJoined(int index) const;

    Q_INVOKABLE QString getSystemDateString() const;
    Q_INVOKABLE QString copyImageToUploads(const QString &sourceUrl);

    Q_INVOKABLE void cleanOrphanedImages();

signals:
    void filePathChanged();
    void entriesChanged();
    void dirtyChanged();
    void statusMessageAlert(const QString &message, bool isSuccess);

private:
    void organizeEntriesByVersion();
    QString sanitizeUrlToNativePath(const QString &rawPath) const;

    // Generates a deterministic, isolated sandbox folder path for the current project
    QString getAssetDirectoryPath() const;

    QString m_filePath;
    QList<LogVersionEntry> m_entries;
    bool m_isDirty = false;
};

#endif // CHANGELOGMANAGER_H
