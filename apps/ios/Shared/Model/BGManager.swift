//
//  BGManager.swift
//  SimpleX
//
//  Created by Evgeny Poberezkin on 08/02/2022.
//  Copyright © 2022 SimpleX Chat. All rights reserved.
//

import Foundation
import BackgroundTasks

private let receiveTaskId = "chat.simplex.app.receive"

// TCP timeout + 2 sec
private let waitForMessages: TimeInterval = 6

private let bgRefreshInterval: TimeInterval = 450

class BGManager {
    static let shared = BGManager()
    var chatReceiver: ChatReceiver?
    var bgTimer: Timer?
    var completed = false

    func register() {
        logger.debug("BGManager.register")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: receiveTaskId, using: nil) { task in
            self.handleRefresh(task as! BGAppRefreshTask)
        }
    }

    func schedule() {
        logger.debug("BGManager.schedule")
        let request = BGAppRefreshTaskRequest(identifier: receiveTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: bgRefreshInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.error("BGManager.schedule error: \(error.localizedDescription)")
        }
    }

    private func handleRefresh(_ task: BGAppRefreshTask) {
        logger.debug("BGManager.handleRefresh")
        schedule()
        self.completed = false

        let completeTask: (String) -> Void = { reason in
            logger.debug("BGManager.handleRefresh completeTask: \(reason)")
            if !self.completed {
                self.completed = true
                self.chatReceiver?.stop()
                self.chatReceiver = nil
                self.bgTimer?.invalidate()
                self.bgTimer = nil
                task.setTaskCompleted(success: true)
            }
        }

        task.expirationHandler = { completeTask("expirationHandler") }
        DispatchQueue.main.async {
            initializeChat()
            if ChatModel.shared.currentUser == nil {
                completeTask("no current user")
                return
            }
            logger.debug("BGManager.handleRefresh: starting chat")
            let cr = ChatReceiver()
            self.chatReceiver = cr
            cr.start()
            RunLoop.current.add(Timer(timeInterval: 2, repeats: true) { timer in
                logger.debug("BGManager.handleRefresh: timer")
                self.bgTimer = timer
                if cr.lastMsgTime.distance(to: Date.now) >= waitForMessages {
                    completeTask("timer (no messages after \(waitForMessages) seconds)")
                }
            }, forMode: .default)
        }
    }
}