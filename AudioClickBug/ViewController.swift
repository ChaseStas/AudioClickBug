import AVFoundation
import SnapKit
import UIKit

class ViewController: UIViewController {

	private var playerLayer: AVPlayerLayer!
	// AVPlayer to play the video
	private var player: AVPlayer?

	private let composition = CompositionGenerator()

	override func viewDidLoad() {
		super.viewDidLoad()


		let (composition, audioMix) = composition.generate()
		let playerItem = AVPlayerItem(asset: composition)
		playerItem.audioMix = audioMix

		player = AVPlayer(playerItem: playerItem)
		playerLayer = .init(player: player)
		// Adjust the frame of the player layer to fit the view bounds
		playerLayer.frame = view.bounds
		playerLayer.videoGravity = .resizeAspect

		// Add player layer to the view's layer
		view.layer.addSublayer(playerLayer)

		// Create play button
		let playButton = UIButton(type: .system)
		playButton.setTitle("Play", for: .normal)
		playButton.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
		view.addSubview(playButton)

		playButton.snp.makeConstraints { make in
			make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
			make.leading.equalToSuperview().offset(100)
			make.width.equalTo(80)
			make.height.equalTo(50)
		}

		// Create stop button
		let stopButton = UIButton(type: .system)
		stopButton.setTitle("Stop", for: .normal)
		stopButton.addTarget(self, action: #selector(didTapStopButton), for: .touchUpInside)
		view.addSubview(stopButton)

		stopButton.snp.makeConstraints { make in
			make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-50)
			make.leading.equalToSuperview().offset(200)
			make.width.equalTo(80)
			make.height.equalTo(50)
		}
		playerLayer.player = player
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		playerLayer.frame = view.bounds
	}

	// MARK: - Buttons
	@objc func didTapPlayButton() {
		player?.seek(to: .zero)
		player?.play()
	}

	@objc func didTapStopButton() {
		player?.pause()
	}

	// MARK: - Composition generator
	final class CompositionGenerator {
		private let videoURL1 = Bundle.main.url(forResource: "video1", withExtension: "MOV")!
		private let videoURL2 = Bundle.main.url(forResource: "video2", withExtension: "MP4")!

		private var audioParameters: [AVMutableAudioMixInputParameters] = []
		func createInputParameter(track: AVCompositionTrack) -> AVMutableAudioMixInputParameters {
			var inputParameter = audioParameters.first { (parameters) -> Bool in
				return parameters.trackID == track.trackID
			}
			if inputParameter == nil {
				inputParameter = AVMutableAudioMixInputParameters(track: track)
				inputParameter?.trackID = track.trackID
				audioParameters.append(inputParameter!)
			}

			return inputParameter!
		}

		func generate() -> (AVComposition, AVAudioMix) {
			// Create AVComposition
			let composition = AVMutableComposition()

			let asset1 = AVAsset(url: videoURL1)
			let asset2 = AVAsset(url: videoURL2)
			let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
			let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

			var time = CMTime.zero
			var audioParams: [ AVMutableAudioMixInputParameters] = []
			for asset in [asset1, asset2] {

				let duration = asset.duration
				let timeRange = CMTimeRange(start: .zero, duration: duration)
				do {
					let audio = asset.tracks(withMediaType: .audio)[0]
					try audioTrack.insertTimeRange(timeRange, of: audio, at: time)
					try videoTrack.insertTimeRange(timeRange, of: asset.tracks(withMediaType: .video)[0], at: time)

					let mix = createInputParameter(track: audioTrack)
					if asset == asset1 {
						mix.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: CMTimeRange(start: .zero, duration: duration))
					} else {
						mix.setVolumeRamp(fromStartVolume: 0, toEndVolume: 0, timeRange: CMTimeRange(start: time, duration: duration))
					}

					if !audioParams.contains(mix) {
						audioParams.append(mix)
					}
				} catch {

				}

				time = CMTimeAdd(time, duration)
			}


			let audioMix = AVMutableAudioMix()
			audioMix.inputParameters = audioParams
			return (composition, audioMix)
		}
	}
}

