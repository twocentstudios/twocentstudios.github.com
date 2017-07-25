import Foundation

struct User {
    let id: Int
    let avatarURL: URL
    let username: String
    let friendsCount: Int
    let location: String
    let website: URL
}

struct Post {
    let id: Int
    let date: Date
    let body: String
}

struct Photo {
    let id: Int
    let date: Date
    let url: URL
}

struct D0 {
    struct UserViewModel {
        let avatarURL: URL?
        let username: String?
        let friendsCount: NSAttributedString?
        let location: String?
        let website: String?
        
    //        init(user: User) { /* ... */ }
    }
}

struct D1 {
    struct UserViewModel {
        let avatarURL: URL?
        let username: String?
        let friendsCount: NSAttributedString?
        let location: String?
        let website: String?
        
        let isHidden: Bool
        
//        init(user: User?) { /* ... */ }
    }

    struct ErrorViewModel {
        let message: String?
        let actionTitle: String?
        
        let isHidden: Bool
        
//        init(error: Error?) { /* ... */ }
    }

    struct LoadingViewModel {
        let isHidden: Bool
    }

    struct ProfileViewModel {
        enum State {
            case initialized
            case loading
            case loaded(User)
            case failed(Error)
        }
        
        let state: State
        
        let userViewModel: UserViewModel
        let loadingViewModel: LoadingViewModel
        let errorViewModel: ErrorViewModel
        
//        init(state: State) {
//            self.state = state
//
//            switch state {
//            case .initialized:
//                self.userViewModel = UserViewModel(user: nil)
//                self.loadingViewModel = LoadingViewModel(isHidden: true)
//                self.errorViewModel = ErrorViewModel(error: nil)
//            case .loading:
//                self.userViewModel = UserViewModel(user: nil)
//                self.loadingViewModel = LoadingViewModel(isHidden: false)
//                self.errorViewModel = ErrorViewModel(error: nil)
//            case .loaded(let user):
//                self.userViewModel = UserViewModel(user: user)
//                self.loadingViewModel = LoadingViewModel(isHidden: true)
//                self.errorViewModel = ErrorViewModel(error: nil)
//            case .failed(let error):
//                self.userViewModel = UserViewModel(user: nil)
//                self.loadingViewModel = LoadingViewModel(isHidden: true)
//                self.errorViewModel = ErrorViewModel(error: error)
//            }
//        }
    }
}

struct D2 {
    struct ErrorViewModel {
        let message: String?
        let actionTitle: String?
    }

    struct LoadingTextViewModel {
        enum State {
            case initialized
            case loading
            case loaded(NSAttributedString?)
        }
        
        let state: State
        
        let isLoading: Bool
        let text: NSAttributedString?
    }

    struct ProfileHeaderViewModel {
        let avatarURL: URL?
        let username: LoadingTextViewModel
        let friendsCount: LoadingTextViewModel
    }

    struct ProfileAttributeViewModel {
        let name: String?
        let value: String?
    }

    struct PostViewModel {
        let date: String?
        let body: String?
    }
    
    struct UserViewModel {
        enum ViewModelType {
            case profileHeader(ProfileHeaderViewModel)
            case profileError(ErrorViewModel)
            case profileAttribute(ProfileAttributeViewModel)
            case contentHeader(String)
            case contentLoading
            case contentEmpty(String)
            case contentError(ErrorViewModel)
            case post(PostViewModel)
        }
        
        let profileViewModel: ProfileViewModel
        let postsViewModel: PostsViewModel
        
        let viewModels: [ViewModelType]
        
//        init(profileViewModel: ProfileViewModel, postsViewModel: PostsViewModel) { /* ... */ }
    }
    
    struct ProfileViewModel {
        enum ViewModelType {
            case header(ProfileHeaderViewModel)
            case attribute(ProfileAttributeViewModel)
            case error(ErrorViewModel)
        }

        enum State {
            case initialized
            case loading
            case loaded(User)
            case failed(Error)
        }
        
        let state: State
        
        let viewModels: [ViewModelType]
        
//        init(state: State) { /* ... */ }
    }
    
    struct PostsViewModel {
        enum State {
            case initialized
            case loading
            case loaded([PostViewModel])
            case empty
            case failed(Error)
        }
        
        enum ViewModelType {
            case loading
            case post(PostViewModel)
            case empty(String)
            case error(ErrorViewModel)
        }
        
        let state: State
        
        let viewModels: [ViewModelType]
        
//        init(state: State) { /* ... */ }
    }
}



