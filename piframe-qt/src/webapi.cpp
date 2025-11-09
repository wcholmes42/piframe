#include "webapi.h"
#include "photomodel.h"
#include "overlaymanager.h"
#include "configmanager.h"
#include <QJsonArray>
#include <QDebug>

WebApi::WebApi(int port, QObject *parent)
    : QObject(parent)
    , m_port(port)
    , m_server(new QTcpServer(this))
    , m_photoModel(nullptr)
    , m_overlayManager(nullptr)
    , m_configManager(nullptr)
{
    connect(m_server, &QTcpServer::newConnection, this, &WebApi::onNewConnection);
}

WebApi::~WebApi()
{
    stop();
}

bool WebApi::start()
{
    if (!m_server->listen(QHostAddress::Any, m_port)) {
        qCritical() << "Failed to start web API server:" << m_server->errorString();
        return false;
    }

    qInfo() << "Web API server listening on port" << m_port;
    return true;
}

void WebApi::stop()
{
    if (m_server->isListening()) {
        m_server->close();
        qInfo() << "Web API server stopped";
    }
}

void WebApi::onNewConnection()
{
    QTcpSocket *socket = m_server->nextPendingConnection();
    connect(socket, &QTcpSocket::readyRead, this, &WebApi::onReadyRead);
    connect(socket, &QTcpSocket::disconnected, this, &WebApi::onDisconnected);

    emit clientConnected(socket->peerAddress().toString());
    qDebug() << "Client connected:" << socket->peerAddress().toString();
}

void WebApi::onReadyRead()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket *>(sender());
    if (!socket) return;

    QByteArray data = socket->readAll();
    handleRequest(socket, data);
}

void WebApi::onDisconnected()
{
    QTcpSocket *socket = qobject_cast<QTcpSocket *>(sender());
    if (!socket) return;

    emit clientDisconnected(socket->peerAddress().toString());
    qDebug() << "Client disconnected:" << socket->peerAddress().toString();
    socket->deleteLater();
}

void WebApi::handleRequest(QTcpSocket *socket, const QByteArray &data)
{
    // Parse HTTP request (simplified - real implementation would use proper HTTP library)
    QString request = QString::fromUtf8(data);
    QStringList lines = request.split("\r\n");

    if (lines.isEmpty()) {
        sendResponse(socket, 400, "Bad Request");
        return;
    }

    QStringList requestLine = lines[0].split(" ");
    if (requestLine.size() < 2) {
        sendResponse(socket, 400, "Bad Request");
        return;
    }

    QString method = requestLine[0];
    QString path = requestLine[1];

    qDebug() << "Request:" << method << path;

    // Find JSON body if present
    QJsonObject params;
    int bodyStart = request.indexOf("\r\n\r\n");
    if (bodyStart != -1) {
        QString body = request.mid(bodyStart + 4);
        QJsonDocument doc = QJsonDocument::fromJson(body.toUtf8());
        if (doc.isObject()) {
            params = doc.object();
        }
    }

    // Route to appropriate handler
    QJsonObject response;

    if (path == "/api/status" || path.startsWith("/api/status?")) {
        response = handleStatus();
        sendResponse(socket, 200, response);
    }
    else if (path == "/api/control") {
        response = handleControl(params);
        sendResponse(socket, 200, response);
    }
    else if (path == "/api/config") {
        response = handleConfig(params);
        sendResponse(socket, 200, response);
    }
    else if (path == "/api/message") {
        response = handleMessage(params);
        sendResponse(socket, 200, response);
    }
    else if (path == "/api/photos") {
        response = handlePhotos();
        sendResponse(socket, 200, response);
    }
    else {
        sendResponse(socket, 404, "Not Found");
    }
}

void WebApi::sendResponse(QTcpSocket *socket, int statusCode, const QJsonObject &data)
{
    QString statusText = (statusCode == 200) ? "OK" :
                        (statusCode == 404) ? "Not Found" :
                        (statusCode == 400) ? "Bad Request" : "Error";

    QByteArray json = QJsonDocument(data).toJson(QJsonDocument::Compact);

    QString response = QString("HTTP/1.1 %1 %2\r\n").arg(statusCode).arg(statusText);
    response += "Content-Type: application/json\r\n";
    response += "Access-Control-Allow-Origin: *\r\n";
    response += QString("Content-Length: %1\r\n").arg(json.size());
    response += "Connection: close\r\n";
    response += "\r\n";

    socket->write(response.toUtf8());
    socket->write(json);
    socket->flush();
    socket->disconnectFromHost();
}

void WebApi::sendResponse(QTcpSocket *socket, int statusCode, const QString &message)
{
    QJsonObject obj;
    obj["message"] = message;
    obj["status"] = statusCode;
    sendResponse(socket, statusCode, obj);
}

QJsonObject WebApi::handleStatus()
{
    QJsonObject status;
    status["success"] = true;

    if (m_photoModel) {
        QJsonObject photos;
        photos["count"] = m_photoModel->photoCount();
        photos["current_index"] = m_photoModel->currentIndex();
        photos["is_playing"] = m_photoModel->isPlaying();
        photos["current_photo"] = m_photoModel->currentPhoto();
        status["photos"] = photos;
    }

    if (m_overlayManager) {
        QJsonObject overlays;
        overlays["clock_enabled"] = m_overlayManager->clockEnabled();
        overlays["weather_enabled"] = m_overlayManager->weatherEnabled();
        overlays["holiday_enabled"] = m_overlayManager->holidayEnabled();
        overlays["current_time"] = m_overlayManager->currentTime();
        overlays["active_holiday"] = m_overlayManager->activeHoliday();
        status["overlays"] = overlays;
    }

    return status;
}

QJsonObject WebApi::handleControl(const QJsonObject &params)
{
    QJsonObject response;
    response["success"] = false;

    if (!m_photoModel) {
        response["error"] = "Photo model not available";
        return response;
    }

    QString action = params["action"].toString();

    if (action == "play") {
        m_photoModel->start();
        response["success"] = true;
    }
    else if (action == "pause") {
        m_photoModel->pause();
        response["success"] = true;
    }
    else if (action == "stop") {
        m_photoModel->stop();
        response["success"] = true;
    }
    else if (action == "next") {
        m_photoModel->next();
        response["success"] = true;
    }
    else if (action == "previous") {
        m_photoModel->previous();
        response["success"] = true;
    }
    else if (action == "refresh") {
        m_photoModel->refreshPhotos();
        response["success"] = true;
    }
    else {
        response["error"] = "Unknown action";
    }

    return response;
}

QJsonObject WebApi::handleConfig(const QJsonObject &params)
{
    QJsonObject response;
    response["success"] = false;

    if (!m_configManager) {
        response["error"] = "Config manager not available";
        return response;
    }

    // GET: Return current config
    if (params.isEmpty()) {
        QJsonObject config;
        config["slideshow_interval"] = m_configManager->slideshowInterval();
        config["transition_type"] = m_configManager->transitionType();
        config["shuffle"] = m_configManager->shufflePhotos();
        config["brightness_mode"] = m_configManager->brightnessMode();
        response["config"] = config;
        response["success"] = true;
        return response;
    }

    // POST: Update config
    if (params.contains("slideshow_interval")) {
        m_configManager->setSlideshowInterval(params["slideshow_interval"].toInt());
    }
    if (params.contains("transition_type")) {
        m_configManager->setTransitionType(params["transition_type"].toString());
    }
    if (params.contains("shuffle")) {
        m_configManager->setShufflePhotos(params["shuffle"].toBool());
    }
    if (params.contains("brightness_mode")) {
        m_configManager->setBrightnessMode(params["brightness_mode"].toString());
    }

    m_configManager->save();
    response["success"] = true;

    return response;
}

QJsonObject WebApi::handleMessage(const QJsonObject &params)
{
    QJsonObject response;
    response["success"] = false;

    if (!m_overlayManager) {
        response["error"] = "Overlay manager not available";
        return response;
    }

    QString text = params["text"].toString();
    int duration = params["duration"].toInt(10);

    if (text.isEmpty()) {
        response["error"] = "Message text is required";
        return response;
    }

    m_overlayManager->sendMessage(text, duration);
    response["success"] = true;

    return response;
}

QJsonObject WebApi::handlePhotos()
{
    QJsonObject response;
    response["success"] = false;

    if (!m_photoModel) {
        response["error"] = "Photo model not available";
        return response;
    }

    response["count"] = m_photoModel->photoCount();
    response["source"] = m_photoModel->photoSource();
    response["success"] = true;

    return response;
}
