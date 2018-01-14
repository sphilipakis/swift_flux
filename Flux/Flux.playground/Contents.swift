//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport
import Flux

enum CounterAction {
    case increment
    case decrement
    class Creator: ActionCreating {
        class func increment() {
            dispatch(action: CounterAction.increment)
        }
        class func decrement() {
            dispatch(action: CounterAction.decrement)
        }
    }
}

class CounterStore: FASFluxStore {
    var counter: Int = 0
    override init() {
        super.init()
        registerWithDispatcher(FASFluxDispatcher.main) { [weak self] action in
            guard let action = action as? CounterAction else { return }
            switch action {
            case .increment:
                self?.counter += 1
                self?.emitChange()
            case .decrement:
                self?.counter -= 1
                self?.emitChange()
            }
        }
    }
}



let counterStore = CounterStore()


class MyViewController : UIViewController {
    weak var label: UILabel!
    
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Counter: 0"
        label.textColor = .black
        view.addSubview(label)
        self.label = label

        let incButton = UIButton(type: .system)
        incButton.frame = CGRect(x: 150, y:250, width: 200, height: 20)
        incButton.titleLabel?.textAlignment = .center
        incButton.setTitle("Increment", for: .normal)
        incButton.addTarget(self, action: #selector(MyViewController.incrementAction(sender:)), for: .touchUpInside)
        view.addSubview(incButton)
        
        let decButton = UIButton(type: .system)
        decButton.frame = CGRect(x: 150, y:290, width: 200, height: 20)
        decButton.titleLabel?.textAlignment = .center
        decButton.setTitle("Decrement", for: .normal)
        decButton.addTarget(self, action: #selector(MyViewController.decrementAction(sender:)), for: .touchUpInside)
        view.addSubview(decButton)
        
        self.view = view
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        counterStore.add(observer: self)
    }
    
    @objc func incrementAction(sender: UIButton) {
        CounterAction.Creator.increment()
    }
    @objc func decrementAction(sender: UIButton) {
        CounterAction.Creator.decrement()
    }
}
extension MyViewController: FASStoreObserving {
    func observeChange(store: FASFluxStore, userInfo: [AnyHashable : Any]?) {
        guard let counterStore = store as? CounterStore else { return }
        self.label.text = "Counter: \(counterStore.counter)"
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()


//PlaygroundPage.current.needsIndefiniteExecution = true

