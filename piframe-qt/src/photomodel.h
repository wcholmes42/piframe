#ifndef PHOTOMODEL_H
#define PHOTOMODEL_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>
#include <QDir>
#include <QFileSystemWatcher>

class PhotoModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString currentPhoto READ currentPhoto NOTIFY currentPhotoChanged)
    Q_PROPERTY(int photoCount READ photoCount NOTIFY photoCountChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(QString photoSource READ photoSource NOTIFY photoSourceChanged)

public:
    explicit PhotoModel(QObject *parent = nullptr);

    QString currentPhoto() const { return m_currentPhoto; }
    int photoCount() const { return m_photos.count(); }
    int currentIndex() const { return m_currentIndex; }
    bool isPlaying() const { return m_isPlaying; }
    QString photoSource() const { return m_photoSource; }

    void setPhotoSource(const QString &path);
    void setShuffle(bool shuffle);
    void setInterval(int seconds);

public slots:
    void start();
    void stop();
    void pause();
    void resume();
    void next();
    void previous();
    void loadPhotos();
    void refreshPhotos();

signals:
    void currentPhotoChanged(const QString &photo);
    void photoCountChanged(int count);
    void currentIndexChanged(int index);
    void isPlayingChanged(bool playing);
    void photoSourceChanged(const QString &source);
    void photosLoaded();
    void photoLoadError(const QString &error);

private slots:
    void advancePhoto();
    void onDirectoryChanged(const QString &path);

private:
    void scanPhotos();
    void setCurrentPhoto(const QString &photo);
    void setCurrentIndex(int index);

    QString m_photoSource;
    QString m_currentPhoto;
    QStringList m_photos;
    int m_currentIndex;
    bool m_shuffle;
    int m_interval;
    bool m_isPlaying;
    QTimer *m_timer;
    QFileSystemWatcher *m_watcher;

    QStringList m_supportedFormats;
};

#endif // PHOTOMODEL_H
