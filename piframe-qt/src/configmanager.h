#ifndef CONFIGMANAGER_H
#define CONFIGMANAGER_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonDocument>

class ConfigManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int displayWidth READ displayWidth NOTIFY configChanged)
    Q_PROPERTY(int displayHeight READ displayHeight NOTIFY configChanged)
    Q_PROPERTY(bool fullscreen READ fullscreen NOTIFY configChanged)
    Q_PROPERTY(int slideshowInterval READ slideshowInterval NOTIFY configChanged)
    Q_PROPERTY(int transitionDuration READ transitionDuration NOTIFY configChanged)
    Q_PROPERTY(QString transitionType READ transitionType NOTIFY configChanged)
    Q_PROPERTY(bool crystalBallEnabled READ crystalBallEnabled NOTIFY configChanged)

public:
    explicit ConfigManager(const QString &configPath, QObject *parent = nullptr);

    bool load();
    bool save();

    // Display settings
    int displayWidth() const { return m_displayWidth; }
    int displayHeight() const { return m_displayHeight; }
    bool fullscreen() const { return m_fullscreen; }
    int framerate() const { return m_framerate; }

    // Slideshow settings
    int slideshowInterval() const { return m_slideshowInterval; }
    int transitionDuration() const { return m_transitionDuration; }
    QString transitionType() const { return m_transitionType; }
    bool shufflePhotos() const { return m_shuffle; }
    QString photoSource() const { return m_photoSource; }
    bool crystalBallEnabled() const { return m_crystalBallEnabled; }

    // Brightness settings
    QString brightnessMode() const { return m_brightnessMode; }
    QString currentBrightnessFolder() const;

    // Overlay settings
    bool clockEnabled() const { return m_clockEnabled; }
    bool weatherEnabled() const { return m_weatherEnabled; }
    bool textOverlayEnabled() const { return m_textOverlayEnabled; }
    bool holidayEnabled() const { return m_holidayEnabled; }

    // Network settings
    int apiPort() const { return m_apiPort; }
    int websocketPort() const { return m_websocketPort; }
    QString unraidHost() const { return m_unraidHost; }
    QString unraidShare() const { return m_unraidShare; }

    // Storage settings
    QString usbMount() const { return m_usbMount; }
    QString networkSource() const { return m_networkSource; }
    int syncInterval() const { return m_syncInterval; }
    bool autoSync() const { return m_autoSync; }

    // System settings
    QString logLevel() const { return m_logLevel; }
    bool tmpfsLogs() const { return m_tmpfsLogs; }
    bool readonlySd() const { return m_readonlySd; }

public slots:
    void setSlideshowInterval(int interval);
    void setTransitionType(const QString &type);
    void setShufflePhotos(bool shuffle);
    void setCrystalBallEnabled(bool enabled);
    void setClockEnabled(bool enabled);
    void setWeatherEnabled(bool enabled);
    void setHolidayEnabled(bool enabled);
    void setBrightnessMode(const QString &mode);

signals:
    void configChanged();
    void slideshowIntervalChanged(int interval);
    void brightnessChanged(const QString &level);

private:
    QString m_configPath;
    QJsonObject m_config;

    // Cached values
    int m_displayWidth;
    int m_displayHeight;
    bool m_fullscreen;
    int m_framerate;
    int m_slideshowInterval;
    int m_transitionDuration;
    QString m_transitionType;
    bool m_shuffle;
    QString m_photoSource;
    bool m_crystalBallEnabled;
    QString m_brightnessMode;
    bool m_clockEnabled;
    bool m_weatherEnabled;
    bool m_textOverlayEnabled;
    bool m_holidayEnabled;
    int m_apiPort;
    int m_websocketPort;
    QString m_unraidHost;
    QString m_unraidShare;
    QString m_usbMount;
    QString m_networkSource;
    int m_syncInterval;
    bool m_autoSync;
    QString m_logLevel;
    bool m_tmpfsLogs;
    bool m_readonlySd;

    void parseConfig();
};

#endif // CONFIGMANAGER_H
