//
//  ViewController.swift
//  WebView
//
//  Created by Yulia on 18.09.2021.
//

import UIKit
import WebKit
import MobileCoreServices
import MessageUI
import CoreLocation
import ContactsUI

class WVViewController: UIViewController {
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getWebView()
        getLocation()
    }
    
    func getWebView() {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        userContentController.add(self, name: WVConstants.openCamera)
        userContentController.add(self, name: WVConstants.openGallery)
        userContentController.add(self, name: WVConstants.openCameraOrGallery)
        userContentController.add(self, name: WVConstants.openPhone)
        userContentController.add(self, name: WVConstants.openSMS)
        userContentController.add(self, name: WVConstants.determineLocation)
        userContentController.add(self, name: WVConstants.openEmail)
        userContentController.add(self, name: WVConstants.importContact)

        config.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        view.addSubview(webView)

        let layoutGuide = view.safeAreaLayoutGuide

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor).isActive = true

        if let url = URL(string: WVConstants.url) {
            webView.load(URLRequest(url: url))
        }
    }
    
    func getLocation() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()

        guard CLLocationManager.locationServicesEnabled() else{
            print("Error gps")
            return
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) == true else { return }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func openPhotoLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true else { return }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary;
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func openCameraOrGallety() {
        let alert = UIAlertController(title: "Open camera or gallery", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Open camera",style: UIAlertAction.Style.default) {_ in
            self.openCamera()
        })
        alert.addAction(UIAlertAction(title: "Open gallery", style: UIAlertAction.Style.default) {_ in
            self.openPhotoLibrary()
        })

        alert.addAction(UIAlertAction(title: "Chanel", style: .cancel) { _ in })
        
        present(alert, animated: true, completion: nil)
    }
    
    func callNumber(phoneNumber: String) {
        guard let url = URL(string: "telprompt://\(phoneNumber)"),
            UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func sendSMS() {
        guard MFMessageComposeViewController.canSendText() else { return }

        let messageVC = MFMessageComposeViewController()
        messageVC.body = "Enter a message details here";
        messageVC.recipients = ["recipients_number_here"]
        messageVC.messageComposeDelegate = self
        self.present(messageVC, animated: true, completion: nil)
    }
    
    func sendLocationRequest() {
        locationManager.requestLocation()
    }
    
    func sendEmail() {
        guard MFMailComposeViewController.canSendMail() else { return }

        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(["test@test.test"])
        mail.setSubject("Enter a subject here")
        mail.setMessageBody("Enter a message details here", isHTML: false)

        present(mail, animated: true, completion: nil)
    }
    
    func importContact() {
        let vc = CNContactPickerViewController()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
}

extension WVViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
        
        print("Action canceled")
    }
}

extension WVViewController: UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.presentingViewController?.dismiss(animated: true)
        
        print("Photo captured")
    }
}

extension WVViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
            case .cancelled:
                print("Message was cancelled")
            case .failed:
                print("Message failed")
            case .sent:
                print("Message was sent")
            default:
                break
        }

        controller.dismiss(animated: true, completion: nil)
    }
}

extension WVViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
      }
}

extension WVViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        guard error == nil else {
            controller.dismiss(animated: true)
            return
        }
        
        switch result {
        case .cancelled:
            print("Mail was cancelled")
        case .failed:
            print("Mail failed to send")
        case .saved:
            print("Mail was saved")
        case .sent:
            print("Mail was sent")
        default:
            break
        }
            
        controller.dismiss(animated: true)
    }
}

extension WVViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        print("Contact Data - \(contact)")
    }
    
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        print("Import contact cancelled")
    }
}

extension WVViewController: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      print("message - \(message)")
    switch message.name {
    case WVConstants.openCamera:
        openCamera()
    case WVConstants.openGallery:
        openPhotoLibrary()
    case WVConstants.openCameraOrGallery:
        openCameraOrGallety()
    case WVConstants.openPhone:
        callNumber(phoneNumber: "1234567")
    case WVConstants.openSMS:
        sendSMS()
    case WVConstants.determineLocation:
        sendLocationRequest()
    case WVConstants.openEmail:
        sendEmail()
    case WVConstants.importContact:
        importContact()
    default:
        return
    }
  }
}


