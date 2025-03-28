//
//  ContentView.swift
//  CoordinatorTest
//
//  Created by Daisoreanu, Laurentiu on 28.03.2025.
//

import SwiftUI

struct ContentView: View {
    private let coordinator = MainCoordinator()
    var body: some View {
        RootView(coordinator: coordinator)
    }
}

#Preview("Content View") {
    ContentView()
}

struct RootView: View {
    @State var coordinator: MainCoordinator
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.build(screen: .first)
                .navigationDestination(for: Screen.self) { screen in
                    coordinator.build(screen: screen)
                }
        }
    }
}

#warning("Warning 2 - I need a better alternative to: '(Int) -> Void'. How wold it look like in the case of multiple completion blocks?")
enum Screen: Hashable {
    case first
    case second(initialValue: Int, callback: (Int) -> Void)
    
    static func == (lhs: Screen, rhs: Screen) -> Bool {
        switch (lhs, rhs) {
        case (.first, .first):
            return true
        case let (.second(lhsValue, _), .second(rhsValue, _)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .first:
            hasher.combine("first")
        case let .second(initialValue, _):
            hasher.combine("second")
            hasher.combine(initialValue)
        }
    }
}

@MainActor @Observable
final class MainCoordinator {
    var path = NavigationPath()
    
    func push(_ screen: Screen) {
        path.append(screen)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    @ViewBuilder
    func build(screen: Screen) -> some View {
        switch screen {
        case .first:
            buildFirstScreen()
        case let .second(initialValue, callback):
            buildSecondScreen(with: initialValue, callback: callback)
        }
    }
    
#warning("Warning 1 - 'buildFirstScreen' gets called each time the NavigationPath changes.")
    @ViewBuilder
    private func buildFirstScreen() -> some View {
        let output = FirstScreenViewModel.Output(onContinue: onContinue)
        let viewModel = FirstScreenViewModel(selectedValue: 1, output: output)
        FirstScreen(viewModel: viewModel)
    }
    
    @ViewBuilder
    private func buildSecondScreen(
        with initialValue: Int,
        callback: @escaping (Int) -> Void
    ) -> some View {
        let output = makeSecondScreenOutput(callback: callback)
        let viewModel = SecondScreenViewModel(initialValue: initialValue, output: output)
        SecondScreen(viewModel: viewModel)
    }
    
    private func onContinue(_ viewModel: FirstScreenViewModel,
                            _ selectedValue: Int,
                            _ updateValue: @escaping (Int) -> Void) -> Void {
        push(.second(initialValue: selectedValue, callback: updateValue))
    }
    
#warning("Warning 3 - I don't like how the syntax looks. I would like to have matching syntax like I have 'onContinue'.")
    private func makeSecondScreenOutput(callback: @escaping (Int) -> Void) -> SecondScreenViewModel.Output {
        return SecondScreenViewModel.Output { [weak self] viewModel, selectedValue in
            guard let self = self else { return }
            callback(selectedValue)
            self.pop()
        }
    }
}

// MARK: - First Screen + ViewModel
struct FirstScreen: View {
    @State var viewModel: FirstScreenViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("First screen")
                .font(.title2)
            
            Text("Value selected: \(viewModel.selectedValue)")
                .font(.body)
            
            Button("Change") {
                viewModel.continueTapped()
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

@Observable
final class FirstScreenViewModel {
#warning("Warning 4 - Should I use typealias for: '(Int) -> Void'?")
    struct Output {
        let onContinue: (_ viewModel: FirstScreenViewModel,
                         _ selectedValue: Int,
                         _ updateValue: @escaping (Int) -> Void) -> Void
    }
    
    var selectedValue: Int
    private let output: Output
    
    init(selectedValue: Int = 1, output: Output) {
        self.selectedValue = selectedValue
        self.output = output
    }
    
    func continueTapped() {
        output.onContinue(self, selectedValue, updateSelectedValue)
    }
    
    private func updateSelectedValue(_ value: Int) {
        selectedValue = value
    }
}

#Preview("First Screen") {
    FirstScreen(viewModel: .init(output: .init(onContinue: { _, _, _ in })))
}

// MARK: - Second Screen + ViewModel
struct SecondScreen: View {
    @State var viewModel: SecondScreenViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Second screen")
                .font(.title2)
            
            Text("Current value: \(viewModel.selectedValue)")
                .font(.body)
            
            Stepper("Adjust value", value: $viewModel.selectedValue, in: 0...100)
            
            Button("Confirm") {
                viewModel.confirmTapped()
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

@Observable
final class SecondScreenViewModel {
    struct Output {
        let onConfirm: (_ viewModel: SecondScreenViewModel, _ selectedValue: Int) -> Void
    }
    
    var selectedValue: Int
    private let output: Output
    
    init(initialValue: Int, output: Output) {
        self.selectedValue = initialValue
        self.output = output
    }
    
    func confirmTapped() {
        output.onConfirm(self, selectedValue)
    }
}

#Preview("Second Screen") {
    SecondScreen(viewModel: .init(initialValue: 1, output: .init(onConfirm: { _, _ in })))
}
