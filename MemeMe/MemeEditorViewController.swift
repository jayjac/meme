//
//  TakeAPictureViewController.swift
//  MemeMe
//
//  Created by Jean-Yves Jacaria on 12/06/2017.
//  Copyright © 2017 Jean-Yves Jacaria. All rights reserved.
//

import UIKit
import MobileCoreServices

class MemeEditorViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButtonItem: UIBarButtonItem!
    @IBOutlet weak var photoLibraryButtonItem: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var containerView: UIView! // View containing the image and the textfields whose snapshot will be turned into the meme
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var emptyView: UIView! // View that is displayed when no image is there
    @IBOutlet weak var tapToChooseAnImageLabel: UILabel!
    @IBOutlet weak var changeFontButton: UIBarButtonItem!
    
    let initialFontSize = 40.0 as CGFloat
    var hasTopTextBeenModified = false
    var hasBottomTextBeenModified = false
    private var font = "Impact"
    let selectedFontUserDefaultsKey = "selectedFont"
    private(set) var selectedFontName: String = "Impact"
    private var dataSourceModel: MemeDataSourceModel?

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /* tapGR toggles the keyboard on/off depending on what half of the main view is being tapped */
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedOnTheView(gesture:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let chooseAnImageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedToChooseAnImage(gesture:)))
        emptyView.addGestureRecognizer(chooseAnImageGestureRecognizer)
        
        cameraButtonItem.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        resetUserInterface()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)

        //If we're being segue'd into this view from the 'sent memes' view controller to edit a meme
        guard let dataSource = dataSourceModel else { return }
        applyDataSource(dataSource)
    }

    
    private func applyDataSource(_ dataSource: MemeDataSourceModel) {
        emptyView.isHidden = true
        topTextField.text = dataSource.topText
        bottomTextField.text = dataSource.bottomText
        imageView.image = UIImage(contentsOfFile: dataSource.originalImageUrl.path)
        topTextField.isEnabled = true
        bottomTextField.isEnabled = true
        shareButton.isEnabled = true
        cancelButton.isEnabled = false
        emptyView.isHidden = true
        changeFontButton.isEnabled = true
        hasTopTextBeenModified = true
        hasBottomTextBeenModified = true
        UserDefaults.standard.setValue(dataSource.fontName, forKey: selectedFontUserDefaultsKey)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        TapWaveAnimation.beginAnimation(on: emptyView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTextFieldFont()
    }

    
    func setTextFieldFont() {
        selectedFontName = UserDefaults.standard.string(forKey: selectedFontUserDefaultsKey) ?? selectedFontName
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [String : Any] = [NSForegroundColorAttributeName: UIColor.white, NSStrokeColorAttributeName: UIColor.black, NSStrokeWidthAttributeName: -5.0, NSFontAttributeName: UIFont(name: selectedFontName, size: initialFontSize)!, NSParagraphStyleAttributeName: paragraphStyle]
        let topText = topTextField.text!
        let bottomText = bottomTextField.text!
        topTextField.attributedText = NSAttributedString(string: topText, attributes: attributes)
        bottomTextField.attributedText = NSAttributedString(string: bottomText, attributes: attributes)
    }


    //MARK:- Gesture Recognizer's selector
    @objc private func tappedOnTheView(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self.view)
        let height = view.frame.height
        if point.y < height / 2 {
            if !topTextField.isFirstResponder {
                topTextField.becomeFirstResponder()
            } else {
                topTextField.resignFirstResponder()
            }
            return
        }
        if point.y >= height / 2 {
            if !bottomTextField.isFirstResponder {
                bottomTextField.becomeFirstResponder()
            } else {
                bottomTextField.resignFirstResponder()
            }
        }
    }
    
    // MARK:- Selector for the GR on the initial empty view
    @objc private func tappedToChooseAnImage(gesture: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action: UIAlertAction) in
                self.showPicker(from: .camera)
            }
            alert.addAction(cameraAction)
        }
        let photoAlbumAction = UIAlertAction(title: "Photo Album", style: .default) { (action: UIAlertAction) in
            self.showPicker(from: .photoLibrary)
        }
        alert.addAction(photoAlbumAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        // Below is for the iPad
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = view
            let height = view.frame.height
            let width = view.frame.width
            presenter.sourceRect = CGRect(x: width / 2, y: height - 40.0, width: 0, height: 0)
        }
        present(alert, animated: true, completion: nil)
    }
    
    private func resetUserInterface() {
        initializeTextFields()
        imageView.image = nil
        shareButton.isEnabled = false
        cancelButton.isEnabled = false
        emptyView.isHidden = false
        changeFontButton.isEnabled = false
    }
    
    
    func initializeTextFields() {
        configureTextField(topTextField, text: "TOP")
        hasTopTextBeenModified = false
        configureTextField(bottomTextField, text: "BOTTOM")
        hasBottomTextBeenModified = false
    }
    
    //MARK: added this func to avoid repetition 
    private func configureTextField(_ textfield: UITextField, text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [String : Any] = [NSForegroundColorAttributeName: UIColor.white, NSStrokeColorAttributeName: UIColor.black, NSStrokeWidthAttributeName: -5.0, NSFontAttributeName: UIFont(name: selectedFontName, size: initialFontSize)!, NSParagraphStyleAttributeName: paragraphStyle]
        textfield.attributedText = NSAttributedString(string: text, attributes: attributes)
        textfield.delegate = self
        textfield.resignFirstResponder()
    }
    
    

    
    //MARK:- Keyboard show/hide notification handlers
    func keyboardWillShow(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            let userInfo = notification.userInfo!
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            let frameEnd = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
            let newOrigin = CGPoint(x: 0, y: -frameEnd.height)
            UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: {
                self.view.frame.origin = newOrigin
            }, completion: nil)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            let userInfo = notification.userInfo!
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double
            UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: {
                self.view.frame.origin = CGPoint.zero
            }, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func setMeme(from dataSource: MemeDataSourceModel) {
        dataSourceModel = dataSource
    }
    
    //MARK:- IBOutlets
    @IBAction func shareMemeButtonWasTapped(_ sender: Any) {
        guard imageView.image != nil else { return }
        let memedImage = Meme.generateMeme(from: containerView)
        let activityVC = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        guard let topText = topTextField.text,
        let bottomText = bottomTextField.text,
            let originalImage = imageView.image else { return }
        if let presenter = activityVC.popoverPresentationController {
            presenter.sourceView = view
            presenter.sourceRect = CGRect(x: 10.0, y: view.bounds.height - 50.0, width: 50.0, height: 50.0)
        }
        activityVC.completionWithItemsHandler = { (type: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            if completed {
                let meme = Meme(topText: topText, bottomText: bottomText, originalImage: originalImage, memedImage: memedImage, fontName: self.selectedFontName, activityType: type)
                MemeManager.saveMemeOnDisk(meme)
                self.navigationController?.popViewController(animated: true)
            }
            
        }
        present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonWasTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        //resetUserInterface()
    }


    @IBAction func takeAPictureThruDevice(_ sender: Any) {
        showPicker(from: .camera)
    }
    
    @IBAction func choosePictureFromPhotoLibrary(_ sender: Any) {
        showPicker(from: .photoLibrary)
    }
    
    
    @IBAction func changeFontButtonWasTapped(_ sender: Any) {
        let fontChooserVC = storyboard!.instantiateViewController(withIdentifier: "FontChooserViewController")
        present(fontChooserVC, animated: true, completion: nil)
    }
    
    private func showPicker(from source: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.mediaTypes = [kUTTypeImage as String] //to make sure user doesn't select videos
        picker.allowsEditing = false
        picker.sourceType = source
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

}






