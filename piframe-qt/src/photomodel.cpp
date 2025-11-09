#include "photomodel.h"
#include <QDirIterator>
#include <QRandomGenerator>
#include <QDebug>

PhotoModel::PhotoModel(QObject *parent)
    : QObject(parent)
    , m_photoSource("/mnt/photocache")
    , m_currentIndex(-1)
    , m_shuffle(true)
    , m_interval(10)
    , m_isPlaying(false)
    , m_timer(new QTimer(this))
    , m_watcher(new QFileSystemWatcher(this))
{
    m_supportedFormats << "*.jpg" << "*.jpeg" << "*.png" << "*.bmp";

    connect(m_timer, &QTimer::timeout, this, &PhotoModel::advancePhoto);
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &PhotoModel::onDirectoryChanged);

    m_timer->setInterval(m_interval * 1000);
}

void PhotoModel::setPhotoSource(const QString &path)
{
    if (m_photoSource != path) {
        // Stop watching old directory
        if (!m_watcher->directories().isEmpty()) {
            m_watcher->removePaths(m_watcher->directories());
        }

        m_photoSource = path;

        // Start watching new directory
        if (QDir(path).exists()) {
            m_watcher->addPath(path);
            loadPhotos();
        } else {
            qWarning() << "Photo source directory does not exist:" << path;
            emit photoLoadError("Photo source directory does not exist");
        }

        emit photoSourceChanged(path);
    }
}

void PhotoModel::setShuffle(bool shuffle)
{
    m_shuffle = shuffle;
}

void PhotoModel::setInterval(int seconds)
{
    m_interval = seconds;
    m_timer->setInterval(seconds * 1000);
}

void PhotoModel::start()
{
    if (m_photos.isEmpty()) {
        loadPhotos();
    }

    if (m_photos.isEmpty()) {
        qWarning() << "No photos to display";
        emit photoLoadError("No photos found in source directory");
        return;
    }

    m_isPlaying = true;
    emit isPlayingChanged(true);

    // Start from first photo or random if shuffle
    if (m_shuffle) {
        setCurrentIndex(QRandomGenerator::global()->bounded(m_photos.count()));
    } else {
        setCurrentIndex(0);
    }

    m_timer->start();
    qInfo() << "Slideshow started with" << m_photos.count() << "photos";
}

void PhotoModel::stop()
{
    m_timer->stop();
    m_isPlaying = false;
    emit isPlayingChanged(false);
    qInfo() << "Slideshow stopped";
}

void PhotoModel::pause()
{
    m_timer->stop();
    m_isPlaying = false;
    emit isPlayingChanged(false);
}

void PhotoModel::resume()
{
    if (!m_photos.isEmpty()) {
        m_timer->start();
        m_isPlaying = true;
        emit isPlayingChanged(true);
    }
}

void PhotoModel::next()
{
    if (m_photos.isEmpty()) {
        return;
    }

    advancePhoto();
}

void PhotoModel::previous()
{
    if (m_photos.isEmpty()) {
        return;
    }

    int newIndex;
    if (m_shuffle) {
        // Random photo
        newIndex = QRandomGenerator::global()->bounded(m_photos.count());
    } else {
        // Previous photo
        newIndex = m_currentIndex - 1;
        if (newIndex < 0) {
            newIndex = m_photos.count() - 1;
        }
    }

    setCurrentIndex(newIndex);
}

void PhotoModel::loadPhotos()
{
    qInfo() << "Loading photos from" << m_photoSource;
    scanPhotos();
}

void PhotoModel::refreshPhotos()
{
    bool wasPlaying = m_isPlaying;
    if (wasPlaying) {
        stop();
    }

    scanPhotos();

    if (wasPlaying && !m_photos.isEmpty()) {
        start();
    }
}

void PhotoModel::advancePhoto()
{
    if (m_photos.isEmpty()) {
        return;
    }

    int newIndex;
    if (m_shuffle) {
        // Random photo (avoid repeating current)
        if (m_photos.count() > 1) {
            do {
                newIndex = QRandomGenerator::global()->bounded(m_photos.count());
            } while (newIndex == m_currentIndex);
        } else {
            newIndex = 0;
        }
    } else {
        // Next photo in sequence
        newIndex = m_currentIndex + 1;
        if (newIndex >= m_photos.count()) {
            newIndex = 0;
        }
    }

    setCurrentIndex(newIndex);
}

void PhotoModel::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    qInfo() << "Photo directory changed, refreshing...";
    // Delay refresh slightly to avoid multiple rapid reloads
    QTimer::singleShot(1000, this, &PhotoModel::refreshPhotos);
}

void PhotoModel::scanPhotos()
{
    QStringList newPhotos;

    QDir dir(m_photoSource);
    if (!dir.exists()) {
        qWarning() << "Photo source directory does not exist:" << m_photoSource;
        emit photoLoadError("Photo source directory does not exist");
        return;
    }

    // Recursively scan for photos
    QDirIterator it(m_photoSource,
                    m_supportedFormats,
                    QDir::Files | QDir::Readable,
                    QDirIterator::Subdirectories);

    while (it.hasNext()) {
        newPhotos << it.next();
    }

    if (newPhotos.isEmpty()) {
        qWarning() << "No photos found in" << m_photoSource;
        emit photoLoadError("No photos found in directory");
    } else {
        qInfo() << "Found" << newPhotos.count() << "photos";
    }

    // Update photo list
    m_photos = newPhotos;
    emit photoCountChanged(m_photos.count());
    emit photosLoaded();

    // Reset current index if out of range
    if (m_currentIndex >= m_photos.count()) {
        setCurrentIndex(m_photos.isEmpty() ? -1 : 0);
    }
}

void PhotoModel::setCurrentPhoto(const QString &photo)
{
    if (m_currentPhoto != photo) {
        m_currentPhoto = photo;
        emit currentPhotoChanged(photo);
        qDebug() << "Current photo:" << photo;
    }
}

void PhotoModel::setCurrentIndex(int index)
{
    if (index >= 0 && index < m_photos.count()) {
        m_currentIndex = index;
        setCurrentPhoto(m_photos[index]);
        emit currentIndexChanged(index);
    }
}
