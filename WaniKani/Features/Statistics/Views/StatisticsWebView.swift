import SwiftUI

struct StatisticsWebView: View {
    let username: String // Should eventually come from User model
    
    init(username: String = "me") { // "me" redirects to current user
        self.username = username
    }
    
    var body: some View {
        WaniKaniWebView(url: URL(string: "https://www.wanikani.com/users/\(username)")!)
            .navigationTitle("Profile")
    }
}
