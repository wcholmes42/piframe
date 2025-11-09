#include "configmanager.h"
#include <QFile>
#include <QJsonArray>
#include <QJsonParseError>
#include <QDateTime>
#include <QDebug>

ConfigManager::ConfigManager(const QString &configPath, QObject *parent)
    : QObject(parent)
    , m_configPath(configPath)
    , m_displayWidth(1920)
    , m_displayHeight(1080)
    , m_fullscreen(true)
    , m_framerate(60)
    , m_slideshowInterval(10)
    , m_transitionDuration(1000)
    , m_transitionType("fade")
    , m_shuffle(true)
    , m_photoSource("/mnt/photocache")
    , m_crystalBallEnabled(false)
    , m_brightnessMode("auto")
    , m_clockEnabled(true)
    , m_weatherEnabled(false)
    , m_textOverlayEnabled(true)
    , m_holidayEnabled(true)
    , m_apiPort(5000)
    , m_websocketPort(5001)
    , m_unraidHost("192.168.68.42")
    , m_unraidShare("Pics/Frame-Optimized")
    , m_usbMount("/mnt/photocache")
    , m_networkSource("//192.168.68.42/Pics/Frame-Optimized")
    , m_syncInterval(60)
    , m_autoSync(true)
    , m_logLevel("INFO")
    , m_tmpfsLogs(true)
    , m_readonlySd(false)
{
}

bool ConfigManager::load()
{
    QFile file(m_configPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Could not open config file:" << m_configPath;
        qWarning() << "Using default configuration";
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);

    if (error.error != QJsonParseError::NoError) {
        qCritical() << "JSON parse error:" << error.errorString();
        return false;
    }

    if (!doc.isObject()) {
        qCritical() << "Config root must be a JSON object";
        return false;
    }

    m_config = doc.object();
    parseConfig();

    qInfo() << "Configuration loaded from" << m_configPath;
    return true;
}

bool ConfigManager::save()
{
    QFile file(m_configPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qCritical() << "Could not write config file:" << m_configPath;
        return false;
    }

    QJsonDocument doc(m_config);
    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();

    qInfo() << "Configuration saved to" << m_configPath;
    return true;
}

void ConfigManager::parseConfig()
{
    // Display settings
    if (m_config.contains("display")) {
        QJsonObject display = m_config["display"].toObject();
        m_displayWidth = display["width"].toInt(1920);
        m_displayHeight = display["height"].toInt(1080);
        m_fullscreen = display["fullscreen"].toBool(true);
        m_framerate = display["framerate"].toInt(60);
    }

    // Slideshow settings
    if (m_config.contains("slideshow")) {
        QJsonObject slideshow = m_config["slideshow"].toObject();
        m_slideshowInterval = slideshow["interval_seconds"].toInt(10);
        m_transitionDuration = slideshow["transition_duration_ms"].toInt(1000);
        m_transitionType = slideshow["transition_type"].toString("fade");
        m_shuffle = slideshow["shuffle"].toBool(true);
        m_photoSource = slideshow["photo_source"].toString("/mnt/photocache");
        m_crystalBallEnabled = slideshow["crystal_ball_enabled"].toBool(false);
    }

    // Brightness settings
    if (m_config.contains("brightness")) {
        QJsonObject brightness = m_config["brightness"].toObject();
        m_brightnessMode = brightness["mode"].toString("auto");
    }

    // Overlay settings
    if (m_config.contains("overlays")) {
        QJsonObject overlays = m_config["overlays"].toObject();

        if (overlays.contains("clock")) {
            m_clockEnabled = overlays["clock"].toObject()["enabled"].toBool(true);
        }

        if (overlays.contains("weather")) {
            m_weatherEnabled = overlays["weather"].toObject()["enabled"].toBool(false);
        }

        if (overlays.contains("text")) {
            m_textOverlayEnabled = overlays["text"].toObject()["enabled"].toBool(true);
        }

        if (overlays.contains("holiday")) {
            m_holidayEnabled = overlays["holiday"].toObject()["enabled"].toBool(true);
        }
    }

    // Network settings
    if (m_config.contains("network")) {
        QJsonObject network = m_config["network"].toObject();
        m_apiPort = network["api_port"].toInt(5000);
        m_websocketPort = network["websocket_port"].toInt(5001);
        m_unraidHost = network["unraid_host"].toString("192.168.68.42");
        m_unraidShare = network["unraid_share"].toString("Pics/Frame-Optimized");
    }

    // Storage settings
    if (m_config.contains("storage")) {
        QJsonObject storage = m_config["storage"].toObject();
        m_usbMount = storage["usb_mount"].toString("/mnt/photocache");
        m_networkSource = storage["network_source"].toString("//192.168.68.42/Pics/Frame-Optimized");
        m_syncInterval = storage["sync_interval_minutes"].toInt(60);
        m_autoSync = storage["auto_sync"].toBool(true);
    }

    // System settings
    if (m_config.contains("system")) {
        QJsonObject system = m_config["system"].toObject();
        m_logLevel = system["log_level"].toString("INFO");
        m_tmpfsLogs = system["tmpfs_logs"].toBool(true);
        m_readonlySd = system["readonly_sd"].toBool(false);
    }
}

QString ConfigManager::currentBrightnessFolder() const
{
    if (m_brightnessMode != "auto") {
        return m_brightnessMode;
    }

    // Get current hour
    int hour = QDateTime::currentDateTime().time().hour();

    // Parse schedule from config
    if (m_config.contains("brightness")) {
        QJsonObject brightness = m_config["brightness"].toObject();
        QJsonObject schedule = brightness["schedule"].toObject();

        for (auto it = schedule.begin(); it != schedule.end(); ++it) {
            QString range = it.key();
            QString level = it.value().toString();

            QStringList parts = range.split('-');
            if (parts.size() == 2) {
                int start = parts[0].toInt();
                int end = parts[1].toInt();

                if (hour >= start && hour < end) {
                    return level;
                }
            }
        }
    }

    return "bright";  // Default fallback
}

void ConfigManager::setSlideshowInterval(int interval)
{
    if (m_slideshowInterval != interval) {
        m_slideshowInterval = interval;

        // Update config
        QJsonObject slideshow = m_config["slideshow"].toObject();
        slideshow["interval_seconds"] = interval;
        m_config["slideshow"] = slideshow;

        emit slideshowIntervalChanged(interval);
        emit configChanged();
    }
}

void ConfigManager::setTransitionType(const QString &type)
{
    if (m_transitionType != type) {
        m_transitionType = type;

        QJsonObject slideshow = m_config["slideshow"].toObject();
        slideshow["transition_type"] = type;
        m_config["slideshow"] = slideshow;

        emit configChanged();
    }
}

void ConfigManager::setShufflePhotos(bool shuffle)
{
    if (m_shuffle != shuffle) {
        m_shuffle = shuffle;

        QJsonObject slideshow = m_config["slideshow"].toObject();
        slideshow["shuffle"] = shuffle;
        m_config["slideshow"] = slideshow;

        emit configChanged();
    }
}

void ConfigManager::setClockEnabled(bool enabled)
{
    if (m_clockEnabled != enabled) {
        m_clockEnabled = enabled;

        QJsonObject overlays = m_config["overlays"].toObject();
        QJsonObject clock = overlays["clock"].toObject();
        clock["enabled"] = enabled;
        overlays["clock"] = clock;
        m_config["overlays"] = overlays;

        emit configChanged();
    }
}

void ConfigManager::setWeatherEnabled(bool enabled)
{
    if (m_weatherEnabled != enabled) {
        m_weatherEnabled = enabled;

        QJsonObject overlays = m_config["overlays"].toObject();
        QJsonObject weather = overlays["weather"].toObject();
        weather["enabled"] = enabled;
        overlays["weather"] = weather;
        m_config["overlays"] = overlays;

        emit configChanged();
    }
}

void ConfigManager::setHolidayEnabled(bool enabled)
{
    if (m_holidayEnabled != enabled) {
        m_holidayEnabled = enabled;

        QJsonObject overlays = m_config["overlays"].toObject();
        QJsonObject holiday = overlays["holiday"].toObject();
        holiday["enabled"] = enabled;
        overlays["holiday"] = holiday;
        m_config["overlays"] = overlays;

        emit configChanged();
    }
}

void ConfigManager::setBrightnessMode(const QString &mode)
{
    if (m_brightnessMode != mode) {
        m_brightnessMode = mode;

        QJsonObject brightness = m_config["brightness"].toObject();
        brightness["mode"] = mode;
        m_config["brightness"] = brightness;

        emit brightnessChanged(currentBrightnessFolder());
        emit configChanged();
    }
}

void ConfigManager::setCrystalBallEnabled(bool enabled)
{
    if (m_crystalBallEnabled != enabled) {
        m_crystalBallEnabled = enabled;

        QJsonObject slideshow = m_config["slideshow"].toObject();
        slideshow["crystal_ball_enabled"] = enabled;
        m_config["slideshow"] = slideshow;

        qInfo() << "Crystal ball mode" << (enabled ? "enabled" : "disabled");
        emit configChanged();
    }
}
