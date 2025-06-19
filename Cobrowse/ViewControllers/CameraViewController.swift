import UIKit
import Combine

class CameraViewController: UIViewController {

    @IBOutlet weak var sessionButton: UIBarButtonItem!
    
    @IBOutlet weak var cameraView: CameraView!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var switchCameraButton: UIButton!
    
    private var bag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.start()
        
        subscribeToSession()
        
        // Need to set colors again due to full screen presentation mode
        do {
            takePhotoButton.tintColor = UIColor.cbPrimary
            takePhotoButton.setTitleColor(UIColor.cbSecondary, for: .normal)
            
            switchCameraButton.tintColor = UIColor.cbSecondary
            switchCameraButton.setTitleColor(UIColor.cbPrimary, for: .normal)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        cameraView.layer.cornerRadius = cameraView.bounds.width * 0.5
        
        NSLayoutConstraint.activate([
            cameraView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor,
                                                constant: -(cameraView.bounds.height * 0.5))
        ])
    }
    
    @IBAction func sessionButtonWasTapped(_ sender: Any) {
        cobrowseSession.current?.end()
    }
    
    @IBAction func closeButtonWasTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func takePhotoButtonWasTapped(_ sender: UIButton) {
        guard let image = cameraView.takePhoto()
                else { return }
        
        account.profileImage = image
        dismiss(animated: true)
    }

    @IBAction func switchCameraButtonWasTapped(_ sender: UIButton) {
        cameraView.switchCamera()
    }
}

// MARK: - Subscriptions

extension CameraViewController {
    
    private func subscribeToSession() {
        cobrowseSession.$current.sink { [weak self] session in
            guard let self = self else { return }
            
            sessionButton.isHidden = !(session?.isActive() ?? false)
        }
        .store(in: &bag)
    }
}
