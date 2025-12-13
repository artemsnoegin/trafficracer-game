//
//  GameViewController.swift
//  TrafficRacerGame
//
//  Created by Артём Сноегин on 05.09.2025.
//

import UIKit

class GameViewController: UIViewController, EnemyCarViewDelegate {
    
    private let gameLoop = GameLoop()
    
    private let backgroundView = BackgroundView()
    
    private let controlView = ControlView()
    
    private let playerCarView = PlayerCarView()
    private var playerDidAppear = false
    
    private var enemyCarViews = [EnemyCarView]()
    private var enemySpawnTimer = Timer()
    private var enemySpawnInterval: TimeInterval = 1
    
    private let scoreLabel = UILabel()
    private var score = 0
    
    private var speed: CGFloat = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameLoop.delegate = self
        
        view.addSubview(backgroundView)
        
        view.addSubview(controlView)
        controlView.delegate = playerCarView
        
        addScoreLabel()
        addPauseButton()

        presentStartActionAlert()
    }
    
    func didFinishMovingWithoutCrashing() {
        enemyCarViews.removeAll { $0.superview == nil }
        
        guard playerDidAppear else { return }
        
        score += 1
        scoreLabel.text = String(score)
        
        if score % 25 == 0 {
            speed += 1
            enemySpawnInterval += 0.5
        }
    }
    
    private func addScoreLabel() {
        
        scoreLabel.text = String(score)
        scoreLabel.font = .init(name: "CyberpunkCraftpixPixel", size: UIFont.labelFontSize * 2)
        scoreLabel.textColor = .white

        if let navigationBar = navigationController?.navigationBar {
            
            navigationBar.addSubview(scoreLabel)
            scoreLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                scoreLabel.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor, constant: 18),
                scoreLabel.centerYAnchor.constraint(equalTo: navigationBar.centerYAnchor)
            ])
        }
    }
    
    private func addPauseButton() {
        
        let pauseButton = UIBarButtonItem(title: "Pause", style: .plain, target: self, action: #selector(presentPauseActionAlert))
        
        if let font = UIFont(name: "CyberpunkCraftpixPixel", size: UIFont.labelFontSize) {
            
            pauseButton.setTitleTextAttributes([.font: font], for: .normal)
            pauseButton.setTitleTextAttributes([.font: font], for: .highlighted)
        }
        pauseButton.tintColor = .white
        
        navigationItem.rightBarButtonItem = pauseButton
    }
    
    private func reset() {
        
        speed = 6
        score = 0
        scoreLabel.text = String(self.score)
        
        enemySpawnInterval = 1
        
        playerCarView.place(on: self.view)
        playerDidAppear.toggle()
    }
    
    private func presentStartActionAlert() {
        
        navigationController?.navigationBar.isHidden = true
        
        gameLoop.start()
        
        enemySpawnTimer = Timer.scheduledTimer(timeInterval: enemySpawnInterval, target: self, selector: #selector(spawnEnemies), userInfo: nil, repeats: true)
        enemySpawnTimer.fire()

        let startButtonAlert = ActionAlertViewController()
        
        startButtonAlert.addButton(title: "Start", color: .systemGreen) { [weak self] _ in
            guard let self = self else { return }
            
            self.reset()

            self.dismiss(animated: true)
            
            self.navigationController?.navigationBar.isHidden = false
        }
        
        present(startButtonAlert, animated: true)
    }
    
    @objc private func presentPauseActionAlert() {
        
        navigationController?.navigationBar.isHidden = true
        
        gameLoop.pause()
        
        let pauseAlert = ActionAlertViewController()
        
        pauseAlert.addTitle(title: nil, titleColor: nil, message: "Score: \(score)")
        
        pauseAlert.addButton(title: "Continue", color: .systemIndigo) { [weak self] _ in
            
            self?.gameLoop.restart()

            self?.dismiss(animated: true)
            
            self?.navigationController?.navigationBar.isHidden = false
        }
        
        pauseAlert.addButton(title: "Quit", color: .systemOrange) { [weak self] _ in
            
            self?.removeAllFromSuperview()
            
            self?.gameLoop.invalidate()
            self?.enemySpawnTimer.invalidate()
            
            self?.dismiss(animated: true)
            
            self?.presentStartActionAlert()
        }
        
        present(pauseAlert, animated: true)
    }
    
    private func presentGameOverActionAlert() {
        
        navigationController?.navigationBar.isHidden = true
        
        gameLoop.invalidate()
        enemySpawnTimer.invalidate()
        
        let gameOverActionAlert = ActionAlertViewController()
        
        gameOverActionAlert.addTitle(title: "Game Over", titleColor: .systemRed, message: "Score: \(score)")
        
        gameOverActionAlert.addButton(title: "Restart", color: .systemIndigo) { [weak self] _ in
            
            self?.restartFromGameOver()
            
            self?.dismiss(animated: true)
            
            self?.navigationController?.navigationBar.isHidden = false
        }
        
        gameOverActionAlert.addButton(title: "Quit", color: .systemOrange) { [weak self] _ in
            
            self?.removeAllFromSuperview()
            
            self?.dismiss(animated: true)
            
            self?.presentStartActionAlert()
        }
        
        present(gameOverActionAlert, animated: true)
    }
    
    private func restartFromGameOver() {
        
        removeAllFromSuperview()
        
        reset()
        
        gameLoop.start()
        
        enemySpawnTimer = Timer.scheduledTimer(timeInterval: enemySpawnInterval, target: self, selector: #selector(spawnEnemies), userInfo: nil, repeats: true)
        enemySpawnTimer.fire()
    }
    
    @objc private func spawnEnemies() {
        
        if enemyCarViews.count < 5 {
            
            let enemy = EnemyCarView()
            enemy.place(on: view)
            enemy.delegate = self
            
            enemyCarViews.append(enemy)
        }
    }
    
    private func removeAllFromSuperview() {
        
        playerCarView.removeFromSuperview()
        playerDidAppear.toggle()
        
        enemyCarViews.forEach { $0.removeFromSuperview() }
        enemyCarViews.removeAll()
    }
    
    deinit {
        
        gameLoop.invalidate()
        enemySpawnTimer.invalidate()
    }
}

extension GameViewController: GameLoopDelegate {
    
    func isRunning() {
        
        backgroundView.move(speed: speed)
        
        playerCarView.move(speed: speed)
        
        for enemy in enemyCarViews {
            
            enemy.move(speed: speed)
            
            guard playerDidAppear else { return }
            
            if enemy.frame.insetBy(dx: 4, dy: 4).intersects(playerCarView.frame.insetBy(dx: 4, dy: 4)) {
                presentGameOverActionAlert()
                break
            }
        }
    }
}
