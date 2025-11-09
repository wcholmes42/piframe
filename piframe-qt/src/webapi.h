#ifndef WEBAPI_H
#define WEBAPI_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonDocument>
#include <QJsonObject>

class PhotoModel;
class OverlayManager;
class ConfigManager;

class WebApi : public QObject
{
    Q_OBJECT

public:
    explicit WebApi(int port, QObject *parent = nullptr);
    ~WebApi();

    bool start();
    void stop();

    void setPhotoModel(PhotoModel *model) { m_photoModel = model; }
    void setOverlayManager(OverlayManager *manager) { m_overlayManager = manager; }
    void setConfigManager(ConfigManager *manager) { m_configManager = manager; }

signals:
    void clientConnected(const QString &address);
    void clientDisconnected(const QString &address);
    void requestReceived(const QString &endpoint, const QJsonObject &data);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onDisconnected();

private:
    void handleRequest(QTcpSocket *socket, const QByteArray &data);
    void sendResponse(QTcpSocket *socket, int statusCode, const QJsonObject &data);
    void sendResponse(QTcpSocket *socket, int statusCode, const QString &message);

    // API endpoints
    QJsonObject handleStatus();
    QJsonObject handleControl(const QJsonObject &params);
    QJsonObject handleConfig(const QJsonObject &params);
    QJsonObject handleMessage(const QJsonObject &params);
    QJsonObject handlePhotos();

    int m_port;
    QTcpServer *m_server;
    PhotoModel *m_photoModel;
    OverlayManager *m_overlayManager;
    ConfigManager *m_configManager;
};

#endif // WEBAPI_H
