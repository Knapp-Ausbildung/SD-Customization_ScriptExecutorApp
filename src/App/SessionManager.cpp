#include "SessionManager.hpp"

#include <QDebug>
#include <QVariant>

SessionManager::SessionManager(QObject *parent) : QObject(parent) {

}

QVariantList SessionManager::sessions() const {
    QVariantList result;

    for (AppController *controller : m_sessions) {
        result.append(QVariant::fromValue(static_cast<QObject *>(controller)));
    }

    return result;
}

int SessionManager::activeIndex() const {
    return m_activeIndex;
}

QObject *SessionManager::activeController() const {
    if (m_activeIndex < 0 || m_activeIndex >= m_sessions.size()) {
        return nullptr;
    }

    return m_sessions.at(m_activeIndex);
}

void SessionManager::addSession() {
    auto *controller = new AppController(this);

    m_sessions.append(controller);
    m_activeIndex = static_cast<int>(m_sessions.size()) - 1;

    emit sessionsChanged();
    emit activeSessionChanged();
}

bool SessionManager::removeSession(int index) {
    if (index < 0 || index >= m_sessions.size()) {
        qWarning() << "Ungültiger Sitzungsindex:" << index;
        return false;
    }

    if (m_sessions.size() <= 1) {
        qWarning() << "Die letzte Sitzung kann nicht geschlossen werden!";
        return false;
    }

    const int oldActiveIndex = m_activeIndex;
    AppController *controller = m_sessions.takeAt(index);

    if (index < m_activeIndex) {
        --m_activeIndex;
    } else if (index == m_activeIndex) {
        m_activeIndex = index;
        if (m_activeIndex >= m_sessions.size()) {
            m_activeIndex = static_cast<int>(m_sessions.size()) - 1;
        }
    }

    delete controller;

    emit sessionsChanged();
    if (index <= oldActiveIndex) {
        emit activeSessionChanged();
    }

    return true;
}

bool SessionManager::setActiveIndex(int index) {
    if (index < 0 || index >= m_sessions.size()) {
        qWarning() << "Ungültiger Sitzungsindex: " << index;
        return false;
    }

    if (index == m_activeIndex) {
        return true;
    }

    m_activeIndex = index;
    emit activeSessionChanged();
    return true;
}
