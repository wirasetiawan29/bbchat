//
//  ContactsManager.swift
//
//  Copyright © 2019-2022 Tinode LLC. All rights reserved.
//

import Foundation
import TinodeSDK
//import TinodiosDB

public class ContactHolder {
    var pub: TheCard?
    var uniqueId: String?
    // This is used when the contact was found in search: what was matched.
    var subtitle: String?

    init(pub: TheCard?, uniqueId: String?, subtitle: String? = nil) {
        self.pub = pub
        self.uniqueId = uniqueId
        self.subtitle = subtitle
    }
}

class ContactsManager {
    public static var `default` = ContactsManager()

    private let queue = DispatchQueue(label: "co.tinode.contacts")
    private let userDb: UserDb!
    init() {
        self.userDb = BaseDb.sharedInstance.userDb!
    }
    public func processSubscription(sub: SubscriptionProto) {
        queue.sync {
            processSubsciptionInternal(sub: sub)
        }
    }
    private func processSubsciptionInternal(sub: SubscriptionProto) {
        guard let subId = sub.uniqueId else { return }
        let userId = userDb.getId(for: subId)
        if (sub.deleted) != nil {
            // Subscription deleted. Delete the user.
            if userId >= 0 {
                userDb.deleteRow(for: userId)
            }
        } else {
            if userId >= 0 {
                // Existing contact.
                if !userDb.update(userId: userId, updated: sub.updated, serializedPub: sub.serializePub()) {
                    Cache.log.error("Could not update user db for userId [%d], subId [%@]", userId, subId)
                }
            } else {
                // New contact.
                userDb.insert(sub: sub)
            }
        }
    }

    public func processDescription(uid: String?, desc: Description<TheCard, PrivateType>) {
        queue.sync {
            processDescriptionInternal(uid: uid, desc: desc)
        }
    }

    private func processDescriptionInternal(uid: String?, desc: Description<TheCard, PrivateType>) {
        guard let uid = uid else { return }
        if let user = userDb.readOne(uid: uid) as? User<TheCard> {
            // Existing contact.
            if user.merge(from: desc) {
                userDb.update(user: user)
            }
        } else {
            let user = User<TheCard>(uid: uid, desc: desc)
            _ = userDb.insert(user: user)
        }
    }

    // Returns contacts from the sqlite database's UserDb.
    public func fetchContacts(withUids uids: [String]? = nil) -> [ContactHolder]? {
        let users: [UserProto]?
        if let uids = uids {
            users = userDb.read(uids: uids)
        } else {
            guard let uid = Cache.tinode.myUid else { return nil }
            users = userDb.readAll(for: uid)
        }
        // Turn users into contacts.
        return users?.map { user in
            let q = user as! DefaultUser
            return ContactHolder(pub: q.pub, uniqueId: q.uid)
        }
    }
}
