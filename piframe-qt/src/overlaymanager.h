#ifndef OVERLAYMANAGER_H
#define OVERLAYMANAGER_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <QDateTime>
#include <QQueue>
#include <QColor>

struct TextMessage {
    QString text;
    int durationSeconds;
    QDateTime timestamp;
};

class OverlayManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool clockEnabled READ clockEnabled WRITE setClockEnabled NOTIFY clockEnabledChanged)
    Q_PROPERTY(bool weatherEnabled READ weatherEnabled WRITE setWeatherEnabled NOTIFY weatherEnabledChanged)
    Q_PROPERTY(bool holidayEnabled READ holidayEnabled WRITE setHolidayEnabled NOTIFY holidayEnabledChanged)
    Q_PROPERTY(QString currentTime READ currentTime NOTIFY currentTimeChanged)
    Q_PROPERTY(QString currentDate READ currentDate NOTIFY currentDateChanged)
    Q_PROPERTY(QString activeHoliday READ activeHoliday NOTIFY activeHolidayChanged)
    Q_PROPERTY(QString currentMessage READ currentMessage NOTIFY currentMessageChanged)
    Q_PROPERTY(QString weatherInfo READ weatherInfo NOTIFY weatherInfoChanged)
    Q_PROPERTY(int weatherTemp READ weatherTemp NOTIFY weatherTempChanged)
    Q_PROPERTY(QColor adaptiveTextColor READ adaptiveTextColor NOTIFY adaptiveTextColorChanged)
    Q_PROPERTY(QColor adaptiveOutlineColor READ adaptiveOutlineColor NOTIFY adaptiveOutlineColorChanged)
    Q_PROPERTY(float backgroundBrightness READ backgroundBrightness WRITE setBackgroundBrightness NOTIFY backgroundBrightnessChanged)
    Q_PROPERTY(QColor dominantColor READ dominantColor WRITE setDominantColor NOTIFY dominantColorChanged)

public:
    explicit OverlayManager(QObject *parent = nullptr);

    bool clockEnabled() const { return m_clockEnabled; }
    bool weatherEnabled() const { return m_weatherEnabled; }
    bool holidayEnabled() const { return m_holidayEnabled; }
    QString currentTime() const { return m_currentTime; }
    QString currentDate() const { return m_currentDate; }
    QString activeHoliday() const { return m_activeHoliday; }
    QString currentMessage() const { return m_currentMessage; }
    QString weatherInfo() const { return m_weatherInfo; }
    int weatherTemp() const { return m_weatherTemp; }
    QColor adaptiveTextColor() const { return m_adaptiveTextColor; }
    QColor adaptiveOutlineColor() const { return m_adaptiveOutlineColor; }
    float backgroundBrightness() const { return m_backgroundBrightness; }
    QColor dominantColor() const { return m_dominantColor; }

    void setClockEnabled(bool enabled);
    void setWeatherEnabled(bool enabled);
    void setHolidayEnabled(bool enabled);
    void setBackgroundBrightness(float brightness);
    void setDominantColor(const QColor &color);

public slots:
    void start();
    void stop();
    void sendMessage(const QString &text, int durationSeconds = 10);
    void clearMessage();
    void updateWeather();

signals:
    void clockEnabledChanged(bool enabled);
    void weatherEnabledChanged(bool enabled);
    void holidayEnabledChanged(bool enabled);
    void currentTimeChanged(const QString &time);
    void currentDateChanged(const QString &date);
    void activeHolidayChanged(const QString &holiday);
    void currentMessageChanged(const QString &message);
    void weatherInfoChanged(const QString &info);
    void weatherTempChanged(int temp);
    void adaptiveTextColorChanged(const QColor &color);
    void adaptiveOutlineColorChanged(const QColor &color);
    void backgroundBrightnessChanged(float brightness);
    void dominantColorChanged(const QColor &color);

private slots:
    void updateClock();
    void checkHoliday();
    void processMessageQueue();

private:
    QString detectCurrentHoliday() const;
    void calculateAdaptiveColors();

    bool m_clockEnabled;
    bool m_weatherEnabled;
    bool m_holidayEnabled;

    QString m_currentTime;
    QString m_currentDate;
    QString m_activeHoliday;
    QString m_currentMessage;
    QString m_weatherInfo;
    int m_weatherTemp;

    QColor m_adaptiveTextColor;
    QColor m_adaptiveOutlineColor;
    float m_backgroundBrightness;
    QColor m_dominantColor;

    QTimer *m_clockTimer;
    QTimer *m_holidayTimer;
    QTimer *m_messageTimer;
    QTimer *m_weatherTimer;

    QQueue<TextMessage> m_messageQueue;
    QDateTime m_currentMessageExpiry;
};

#endif // OVERLAYMANAGER_H
