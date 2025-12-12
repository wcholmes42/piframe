#include "overlaymanager.h"
#include <QDebug>

OverlayManager::OverlayManager(QObject *parent)
    : QObject(parent)
    , m_clockEnabled(true)
    , m_weatherEnabled(false)
    , m_holidayEnabled(true)
    , m_weatherTemp(0)
    , m_adaptiveTextColor(Qt::white)
    , m_adaptiveOutlineColor(Qt::black)
    , m_backgroundBrightness(0.5)
    , m_dominantColor(Qt::gray)
    , m_clockTimer(new QTimer(this))
    , m_holidayTimer(new QTimer(this))
    , m_messageTimer(new QTimer(this))
    , m_weatherTimer(new QTimer(this))
{
    // Update clock every second
    connect(m_clockTimer, &QTimer::timeout, this, &OverlayManager::updateClock);
    m_clockTimer->setInterval(1000);

    // Check for holiday changes once per hour
    connect(m_holidayTimer, &QTimer::timeout, this, &OverlayManager::checkHoliday);
    m_holidayTimer->setInterval(3600000);  // 1 hour

    // Process message queue
    connect(m_messageTimer, &QTimer::timeout, this, &OverlayManager::processMessageQueue);
    m_messageTimer->setInterval(1000);

    // Update weather every 30 minutes
    connect(m_weatherTimer, &QTimer::timeout, this, &OverlayManager::updateWeather);
    m_weatherTimer->setInterval(1800000);  // 30 minutes
}

void OverlayManager::setClockEnabled(bool enabled)
{
    if (m_clockEnabled != enabled) {
        m_clockEnabled = enabled;
        emit clockEnabledChanged(enabled);

        if (enabled) {
            updateClock();
            m_clockTimer->start();
        } else {
            m_clockTimer->stop();
        }
    }
}

void OverlayManager::setWeatherEnabled(bool enabled)
{
    if (m_weatherEnabled != enabled) {
        m_weatherEnabled = enabled;
        emit weatherEnabledChanged(enabled);

        if (enabled) {
            updateWeather();
            m_weatherTimer->start();
        } else {
            m_weatherTimer->stop();
        }
    }
}

void OverlayManager::setHolidayEnabled(bool enabled)
{
    if (m_holidayEnabled != enabled) {
        m_holidayEnabled = enabled;
        emit holidayEnabledChanged(enabled);

        if (enabled) {
            checkHoliday();
            m_holidayTimer->start();
        } else {
            m_holidayTimer->stop();
            m_activeHoliday.clear();
            emit activeHolidayChanged(m_activeHoliday);
        }
    }
}

void OverlayManager::setBackgroundBrightness(float brightness)
{
    m_backgroundBrightness = qBound(0.0f, brightness, 1.0f);
    emit backgroundBrightnessChanged(m_backgroundBrightness);
    calculateAdaptiveColors();
}

void OverlayManager::setDominantColor(const QColor &color)
{
    if (m_dominantColor != color) {
        m_dominantColor = color;
        emit dominantColorChanged(color);
        calculateAdaptiveColors();
    }
}

void OverlayManager::calculateAdaptiveColors()
{
    // Simple brightness-based contrast - avoids hard-to-read colors like pink/purple
    QColor newTextColor;
    QColor newOutlineColor;

    // Use background brightness to decide: light or dark text
    // Dark backgrounds (< 0.5) get light text, bright backgrounds get dark text
    if (m_backgroundBrightness < 0.45f) {
        // Dark background - use warm white/cream (easy to read, no pink/purple)
        newTextColor = QColor::fromHsvF(0.12f, 0.08f, 0.95f);  // Warm white
    } else if (m_backgroundBrightness < 0.65f) {
        // Medium background - use off-white with slight cyan tint
        newTextColor = QColor::fromHsvF(0.55f, 0.12f, 0.92f);  // Light cyan-white
    } else {
        // Bright background - use dark charcoal (not pure black)
        newTextColor = QColor::fromHsvF(0.6f, 0.15f, 0.18f);  // Dark blue-gray
    }

    // Outline is always black for consistent contrast
    newOutlineColor = Qt::black;

    if (m_adaptiveTextColor != newTextColor) {
        m_adaptiveTextColor = newTextColor;
        emit adaptiveTextColorChanged(m_adaptiveTextColor);
    }

    if (m_adaptiveOutlineColor != newOutlineColor) {
        m_adaptiveOutlineColor = newOutlineColor;
        emit adaptiveOutlineColorChanged(m_adaptiveOutlineColor);
    }
}

void OverlayManager::start()
{
    qInfo() << "Starting overlay manager";

    if (m_clockEnabled) {
        updateClock();
        m_clockTimer->start();
    }

    if (m_holidayEnabled) {
        checkHoliday();
        m_holidayTimer->start();
    }

    if (m_weatherEnabled) {
        updateWeather();
        m_weatherTimer->start();
    }

    m_messageTimer->start();
}

void OverlayManager::stop()
{
    qInfo() << "Stopping overlay manager";
    m_clockTimer->stop();
    m_holidayTimer->stop();
    m_messageTimer->stop();
    m_weatherTimer->stop();
}

void OverlayManager::sendMessage(const QString &text, int durationSeconds)
{
    qInfo() << "Sending message:" << text << "for" << durationSeconds << "seconds";

    TextMessage msg;
    msg.text = text;
    msg.durationSeconds = durationSeconds;
    msg.timestamp = QDateTime::currentDateTime();

    m_messageQueue.enqueue(msg);

    // If no message is currently showing, process queue immediately
    if (m_currentMessage.isEmpty()) {
        processMessageQueue();
    }
}

void OverlayManager::clearMessage()
{
    m_currentMessage.clear();
    m_currentMessageExpiry = QDateTime();
    emit currentMessageChanged(m_currentMessage);
}

void OverlayManager::updateWeather()
{
    // TODO: Implement weather API integration
    // For now, just placeholder
    qDebug() << "Updating weather (not implemented yet)";

    // Example data
    m_weatherTemp = 72;
    m_weatherInfo = "Partly Cloudy";

    emit weatherTempChanged(m_weatherTemp);
    emit weatherInfoChanged(m_weatherInfo);
}

void OverlayManager::updateClock()
{
    QDateTime now = QDateTime::currentDateTime();
    QString newTime = now.toString("h:mm:ss AP");  // 12-hour with AM/PM
    QString newDate = now.toString("dddd, MMMM d, yyyy");

    if (m_currentTime != newTime) {
        m_currentTime = newTime;
        emit currentTimeChanged(m_currentTime);
    }

    if (m_currentDate != newDate) {
        m_currentDate = newDate;
        emit currentDateChanged(m_currentDate);
    }
}

void OverlayManager::checkHoliday()
{
    QString holiday = detectCurrentHoliday();

    if (m_activeHoliday != holiday) {
        m_activeHoliday = holiday;
        emit activeHolidayChanged(m_activeHoliday);
        qInfo() << "Active holiday:" << (holiday.isEmpty() ? "None" : holiday);
    }
}

void OverlayManager::processMessageQueue()
{
    QDateTime now = QDateTime::currentDateTime();

    // Check if current message has expired
    if (!m_currentMessage.isEmpty() && now >= m_currentMessageExpiry) {
        clearMessage();
    }

    // Show next message if queue not empty and no current message
    if (m_currentMessage.isEmpty() && !m_messageQueue.isEmpty()) {
        TextMessage msg = m_messageQueue.dequeue();
        m_currentMessage = msg.text;
        m_currentMessageExpiry = now.addSecs(msg.durationSeconds);
        emit currentMessageChanged(m_currentMessage);
    }
}

QString OverlayManager::detectCurrentHoliday() const
{
    if (!m_holidayEnabled) {
        return QString();
    }

    QDate today = QDate::currentDate();
    int month = today.month();
    int day = today.day();

    // Check for major holidays
    if (month == 12 && day >= 20 && day <= 26) {
        return "christmas";
    }
    else if (month == 10 && day >= 25 && day <= 31) {
        return "halloween";
    }
    else if (month == 1 && day == 1) {
        return "newyear";
    }
    else if (month == 12 && day == 31) {
        return "newyear";
    }
    else if (month == 7 && day == 4) {
        return "independence";
    }
    else if (month == 2 && day == 14) {
        return "valentine";
    }
    else if (month == 3 && day == 17) {
        return "stpatrick";
    }
    else if (month == 11 && day >= 22 && day <= 28) {
        // Rough approximation for Thanksgiving (4th Thursday of November)
        return "thanksgiving";
    }

    return QString();
}
