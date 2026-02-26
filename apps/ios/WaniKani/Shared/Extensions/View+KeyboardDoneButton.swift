import SwiftUI
import UIKit

extension View {
    func keyboardDoneButton(action: (() -> Void)? = nil) -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    if let action {
                        action()
                    } else {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
        }
    }
}
