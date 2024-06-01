//
//  PredefinedChatView.swift
//  Tinodios
//
//  Created by Wira on 07/11/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import UIKit

class PredefinedChatView: UIView {
    
    public var onDidFirstTextSelection: ((_ text: String) -> Void)?
    public var onDidSecondTextSelection: ((_ text: String) -> Void)?
    public var onDidThirdTextSelection: ((_ text: String) -> Void)?
    public var onDidHideContent: ((_ hide: Bool) -> Void)?

    @IBOutlet private weak var collapseView: UIView!
    @IBOutlet private weak var firstTextView: UIView!
    @IBOutlet private weak var secondTextView: UIView!
    @IBOutlet private weak var thirdTextView: UIView!
    @IBOutlet private weak var addActionView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet private weak var collapseImageView: UIImageView!
    
    var isHide = false
    
    let arrowDown = UIImage(named: "ic-chevron-down", in: Bundle.bookingUI, with: .none)
    let arrowUp = UIImage(named: "ic-chevron-up", in: Bundle.bookingUI, with: .none)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    // This is needed for proper calculation of size from constraints.
    override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }

    // MARK: - Configuration

    private func loadNib() {
        let nib = UINib(nibName: "PredefinedChatView", bundle: Bundle(for: type(of: self)))
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        nibView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nibView)
        NSLayoutConstraint.activate([
            nibView.topAnchor.constraint(equalTo: topAnchor),
            nibView.bottomAnchor.constraint(equalTo: bottomAnchor),
            nibView.rightAnchor.constraint(equalTo: rightAnchor),
            nibView.leftAnchor.constraint(equalTo: leftAnchor)
            ])
        configure()
    }
    
    private func configure() {
        let tapFirstRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleFirstTextTapGestureRecognizer))
        firstTextView.addGestureRecognizer(tapFirstRecognizer)
        
        let tapSecondRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSecondTextTapGestureRecognizer))
        secondTextView.addGestureRecognizer(tapSecondRecognizer)
        
        let tapThirdRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleThirdTextTapGestureRecognizer))
        thirdTextView.addGestureRecognizer(tapThirdRecognizer)
        
        let contentHideRecognizer = UITapGestureRecognizer(target: self, action: #selector(showContent))
        collapseView.addGestureRecognizer(contentHideRecognizer)
        
        titleLabel.text = "predefined_chat_title".localized()
        firstLabel.text = "predefined_chat_1".localized()
        secondLabel.text = "predefined_chat_2".localized()
        thirdLabel.text = "predefined_chat_3".localized()
        contentView(hide: false)
    }
    
    private func contentView(hide: Bool) {
        firstTextView.isHidden = hide
        secondTextView.isHidden = hide
        thirdTextView.isHidden = hide
        onDidHideContent?(hide)
        collapseImageView.image = hide ? arrowUp : arrowDown
    }
    
    @objc func showContent(_ sender: UITapGestureRecognizer) {
        
        isHide = !isHide
        contentView(hide: isHide)
    }
    
    
    @objc func handleFirstTextTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        onDidFirstTextSelection?("predefined_chat_1".localized())
    }
    
    @objc func handleSecondTextTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        onDidSecondTextSelection?("predefined_chat_2".localized())
    }
    
    @objc func handleThirdTextTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        onDidThirdTextSelection?("predefined_chat_3".localized())
    }

}
