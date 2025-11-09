#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickView>
#include <QScreen>
#include <QCommandLineParser>
#include <QDebug>

#include "photomodel.h"
#include "overlaymanager.h"
#include "configmanager.h"
#include "webapi.h"

int main(int argc, char *argv[])
{
    // Enable high DPI support
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QGuiApplication app(argc, argv);
    app.setApplicationName("PiFrame Qt");
    app.setApplicationVersion("2.0.0");
    app.setOrganizationName("PiFrame");

    // Command line parser
    QCommandLineParser parser;
    parser.setApplicationDescription("Professional photo frame for Raspberry Pi 5");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption devOption(QStringList() << "d" << "dev",
                                  "Development mode (windowed, verbose logging)");
    parser.addOption(devOption);

    QCommandLineOption configOption(QStringList() << "c" << "config",
                                     "Configuration file path",
                                     "config",
                                     "/opt/piframe/config.json");
    parser.addOption(configOption);

    parser.process(app);

    bool devMode = parser.isSet(devOption);
    QString configPath = parser.value(configOption);

    qInfo() << "Starting PiFrame Qt" << app.applicationVersion();
    qInfo() << "Development mode:" << (devMode ? "ON" : "OFF");
    qInfo() << "Config file:" << configPath;

    // Initialize configuration manager
    ConfigManager configManager(configPath);
    if (!configManager.load()) {
        qCritical() << "Failed to load configuration from" << configPath;
        return 1;
    }

    // Initialize photo model
    PhotoModel photoModel;
    photoModel.setPhotoSource(configManager.photoSource());
    photoModel.setShuffle(configManager.shufflePhotos());

    // Initialize overlay manager
    OverlayManager overlayManager;
    overlayManager.setClockEnabled(configManager.clockEnabled());
    overlayManager.setWeatherEnabled(configManager.weatherEnabled());
    overlayManager.setHolidayEnabled(configManager.holidayEnabled());

    // Initialize web API
    WebApi webApi(configManager.apiPort());
    webApi.setPhotoModel(&photoModel);
    webApi.setOverlayManager(&overlayManager);
    webApi.setConfigManager(&configManager);

    if (!webApi.start()) {
        qWarning() << "Failed to start web API on port" << configManager.apiPort();
        qWarning() << "Continuing without web interface...";
    } else {
        qInfo() << "Web API listening on port" << configManager.apiPort();
    }

    // Create QML engine
    QQmlApplicationEngine engine;

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("photoModel", &photoModel);
    engine.rootContext()->setContextProperty("overlayManager", &overlayManager);
    engine.rootContext()->setContextProperty("configManager", &configManager);
    engine.rootContext()->setContextProperty("devMode", devMode);

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }

    qInfo() << "PiFrame Qt initialized successfully";
    qInfo() << "Screen resolution:" << app.primaryScreen()->size();
    qInfo() << "Refresh rate:" << app.primaryScreen()->refreshRate() << "Hz";

    // Start photo slideshow
    photoModel.start();

    // Start overlay updates
    overlayManager.start();

    return app.exec();
}
