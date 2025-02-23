//
//  ViewController.swift
//  MyAiChatAPP
//
//  Created by 张超 on 2025/2/23.
//

//import UIKit
//
//class ViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//    }
//
//
//}

import UIKit
import MobileCoreServices
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - UI Components
    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray6
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let takePhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("拍摄照片", for: .normal)
        btn.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        return btn
    }()
    
    private let uploadButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("上传照片", for: .normal)
        btn.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        btn.isEnabled = false
        return btn
    }()
    
    // MARK: - Properties
    private var selectedImage: UIImage? {
        didSet {
            uploadButton.isEnabled = selectedImage != nil
            previewImageView.image = selectedImage
        }
    }
    
    private let imagePicker = UIImagePickerController()
    private let uploadURL = URL(string: "https://your-cloud-api.com/upload")! // 替换为你的接口地址
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImagePicker()
        setupActions()
        checkCameraPermission()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let stack = UIStackView(arrangedSubviews: [takePhotoButton, uploadButton])
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(previewImageView)
        view.addSubview(stack)
        
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 40)
        ])
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = true
        imagePicker.showsCameraControls = true
    }
    
    private func setupActions() {
        takePhotoButton.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(handleUpload), for: .touchUpInside)
    }
    
    // MARK: - Camera Methods
    @objc private func handleTakePhoto() {
        present(imagePicker, animated: true)
    }
    
    // MARK: - Upload Methods
    @objc private func handleUpload() {
        guard let image = selectedImage else { return }
        
        // 压缩图片质量（可根据需要调整）
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "错误", message: "图片处理失败")
            return
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // 创建多部分表单数据
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加图片数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 开始上传
        let task = URLSession.shared.uploadTask(with: request, from: body) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "上传失败", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self?.showAlert(title: "服务器错误", message: "请稍后再试")
                    return
                }
                
                self?.showAlert(title: "上传成功", message: "照片已成功上传")
            }
        }
        task.resume()
    }
    
    // MARK: - Helper Methods
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .denied, .restricted:
            showPermissionAlert()
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "需要相机权限",
            message: "请在设置中启用相机权限以使用拍照功能",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            dismiss(animated: true)
            return
        }
        
        selectedImage = image
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

