//
//  SettingsSecurityViewController.swift
//
//  Copyright © 2020-2022 Tinode LLC. All rights reserved.
//

import TinodeSDK
//import TinodiosDB
import UIKit

class SettingsSecurityViewController: UITableViewController {
    @IBOutlet weak var authUsersPermissions: UITableViewCell!
    @IBOutlet weak var anonUsersPermissions: UITableViewCell!
    @IBOutlet weak var authPermissionsLabel: UILabel!
    @IBOutlet weak var anonPermissionsLabel: UILabel!

    @IBOutlet weak var actionChangePassword: UITableViewCell!
    @IBOutlet weak var actionLogOut: UITableViewCell!
    @IBOutlet weak var actionDeleteAccount: UITableViewCell!

    @IBOutlet weak var actionBlockedContacts: UITableViewCell!

    weak var tinode: Tinode!
    weak var me: DefaultMeTopic!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        reloadData()
    }

    private func setup() {
        self.tinode = Cache.tinode
        self.me = self.tinode.getMeTopic()!

        UiUtils.setupTapRecognizer(
            forView: authUsersPermissions,
            action: #selector(SettingsSecurityViewController.permissionsTapped),
            actionTarget: self)
        UiUtils.setupTapRecognizer(
            forView: anonUsersPermissions,
            action: #selector(SettingsSecurityViewController.permissionsTapped),
            actionTarget: self)
        UiUtils.setupTapRecognizer(
            forView: actionChangePassword,
            action: #selector(SettingsSecurityViewController.changePasswordClicked),
            actionTarget: self)
        UiUtils.setupTapRecognizer(
            forView: actionLogOut,
            action: #selector(SettingsSecurityViewController.logoutClicked),
            actionTarget: self)
        UiUtils.setupTapRecognizer(
            forView: actionDeleteAccount,
            action: #selector(SettingsSecurityViewController.deleteAccountClicked),
            actionTarget: self)
    }

    private func reloadData() {
        // Permissions.
        self.authPermissionsLabel.text = me.defacs?.getAuth() ?? ""
        self.authPermissionsLabel.sizeToFit()
        self.anonPermissionsLabel.text = me.defacs?.getAnon() ?? ""
        self.anonPermissionsLabel.sizeToFit()

        if self.tinode.countFilteredTopics(filter: { topic in return topic.topicType.matches(TopicType.user) && !topic.isJoiner }) == 0 {
            // No blocked contacts, disable cell.
            self.actionBlockedContacts.isUserInteractionEnabled = false
            self.actionBlockedContacts.textLabel?.isEnabled = false
            self.actionBlockedContacts.imageView?.tintColor = UIColor.gray
            self.actionBlockedContacts.accessoryType = .none
        } else {
            // Some blocked contacts, enable cell.
            self.actionBlockedContacts.isUserInteractionEnabled = true
            self.actionBlockedContacts.textLabel?.isEnabled = true
            self.actionBlockedContacts.imageView?.tintColor = UIColor.darkText
            self.actionBlockedContacts.accessoryType = .disclosureIndicator
        }
    }

    private func getAcsAndPermissionsChangeType(for sender: UIView) -> (AcsHelper?, UiUtils.PermissionsChangeType?) {
        if sender === authUsersPermissions {
            return (me.defacs?.auth, .updateAuth)
        }
        if sender === anonUsersPermissions {
            return (me.defacs?.anon, .updateAnon)
        }
        return (nil, nil)
    }

    @objc
    func permissionsTapped(sender: UITapGestureRecognizer) {
        guard let v = sender.view else {
            Cache.log.debug("SettingsSecurityVC - permissions tap from no sender view... quitting")
            return
        }
        let (acs, changeTypeOptional) = getAcsAndPermissionsChangeType(for: v)
        guard let acsUnwrapped = acs, let changeType = changeTypeOptional else {
            Cache.log.debug("SettingsSecurityVC - permissionsTapped: could not get acs")
            return
        }
        UiUtils.showPermissionsEditDialog(over: self, acs: acsUnwrapped, callback: { permissions in
            UiUtils.handlePermissionsChange(onTopic: self.me, forUid: nil, changeType: changeType, newPermissions: permissions)?.then(
                onSuccess: { _ in
                    DispatchQueue.main.async { self.reloadData() }
                        return nil
                }
            )
        }, disabledPermissions: "ODS")
    }

    @objc func changePasswordClicked(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: NSLocalizedString("Change Password", comment: "Alert title"), message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("Enter new password", comment: "Alert prompt")
            textField.textContentType = .newPassword
            textField.showSecureEntrySwitch()
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""), style: .default,
            handler: { _ in
                if let newPassword = alert.textFields?.first?.text {
                    self.updatePassword(with: newPassword)
                }
            }))
        self.present(alert, animated: true)
    }

    @objc func logoutClicked(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Are you sure you want to log out?", comment: "Warning in logout alert"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("OK", comment: ""), style: .default,
            handler: { _ in
                self.logout()
            }))
        self.present(alert, animated: true)
    }

    @objc func deleteAccountClicked(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("Are you sure you want to delete your account? It cannot be undone.", comment: "Warning in delete account alert"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Delete", comment: "Alert action"), style: .default,
            handler: { _ in
                self.deleteAccount()
            }))
        self.present(alert, animated: true)
    }

    private func updatePassword(with newPassword: String) {
        guard newPassword.count >= 4 else {
            DispatchQueue.main.async {
                UiUtils.showToast(message: NSLocalizedString("Password too short", comment: "Error message"))
            }
            return
        }
        guard let userName = SharedUtils.getSavedLoginUserName() else {
            DispatchQueue.main.async {
                UiUtils.showToast(message: NSLocalizedString("Login info missing...", comment: "Error message"))
            }
            return
        }
        tinode.updateAccountBasic(uid: nil, username: userName, password: newPassword)
            .then(onSuccess: { msg in
                DispatchQueue.main.async {
                    if let ctrl = msg?.ctrl, 200 <= ctrl.code && ctrl.code < 300 {
                        UiUtils.showToast(message: NSLocalizedString("Password updated", comment: "Success message"), level: .info)
                    } else {
                        UiUtils.showToast(message: "Server error")
                    }
                }
                return nil
            }, onFailure: { err in
                DispatchQueue.main.async {
                    UiUtils.showToast(message: String(format: NSLocalizedString("Could not change password: %@", comment: "Error message"), err.localizedDescription))
                }
                return nil
            })
    }

    private func logout() {
        Cache.log.info("SettingsSecurityVC - logging out")
        UiUtils.logoutAndRouteToLoginVC()
    }

    private func deleteAccount() {
        Cache.log.info("SettingsSecurityVC - deleting account")
        tinode.delCurrentUser(hard: true)
            .thenApply { _ in
                UiUtils.logoutAndRouteToLoginVC()
                return nil
            }
            .thenCatch(UiUtils.ToastFailureHandler)
    }
}
