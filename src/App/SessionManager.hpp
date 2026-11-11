#pragma once

#include <QObject>
#include <QList>
#include <QVariantList>

#include "AppController.hpp"

class SessionManager : public QObject {

    Q_OBJECT

    Q_PROPERTY(QVariantList sessions READ sessions NOTIFY sessionsChanged)
    Q_PROPERTY(int activeIndex READ activeIndex NOTIFY activeSessionChanged)
    Q_PROPERTY(QObject *activeController READ activeController NOTIFY activeSessionChanged)

    public:
        explicit SessionManager(QObject *parent = nullptr);

        QVariantList sessions() const;
        int activeIndex() const;
        QObject *activeController() const;

        Q_INVOKABLE void addSession();
        Q_INVOKABLE bool removeSession(int index);
        Q_INVOKABLE bool setActiveIndex(int index);

    signals:
        void sessionsChanged();
        void activeSessionChanged();
    
    private:
        QList<AppController *> m_sessions;
        int m_activeIndex = -1;   
};