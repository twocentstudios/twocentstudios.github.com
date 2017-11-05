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
        
        init(profileViewModel: ProfileViewModel, postsViewModel: PostsViewModel) {
            self.profileViewModel = profileViewModel
            self.postsViewModel = postsViewModel
            
            var innerViewModels: [ViewModelType] = []
            
            // Convert ProfileViewModel.ViewModelType to UserViewModel.ViewModelType
            let profileInnerViewModels = profileViewModel.viewModels.map(UserViewModel.toViewModels)
            innerViewModels.append(contentsOf: profileInnerViewModels)
            
            // Convert PostsViewModel.ViewModelType to UserViewModel.ViewModelType
            let postsViewModel = postsViewModel.viewModels.map(UserViewModel.toViewModels)
            innerViewModels.append(contentsOf: postsViewModel)
            
            self.viewModels = innerViewModels
        }
        
        private static func toViewModels(_ viewModels: ProfileViewModel.ViewModelType) -> UserViewModel.ViewModelType {
            fatalError()
            /* ... */
        }
        
        private static func toViewModels(_ viewModels: PostsViewModel.ViewModelType) -> UserViewModel.ViewModelType {
            fatalError()
            /* ... */
        }
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
        
        init(state: State) { /* ... */ fatalError() }
    }
    
    struct PostsViewModel {
        enum State {
            case initialized
            case loading
            case loaded([PostViewModel])
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

    struct ProfileViewModelReducer {
        enum Command {
            case load
            case loaded(User)
            case failed(Error)
        }
        
        enum Effect {
            case load
        }
        
        struct State {
            let viewModel: ProfileViewModel
            let effect: Effect?
        }
        
        static func reduce(state: State, command: Command) -> State {
            let viewModel: ProfileViewModel = state.viewModel
            let _: Effect? = state.effect
            let viewModelState: ProfileViewModel.State = viewModel.state
            let noChange = State(viewModel: viewModel, effect: nil)
            
            switch (command, viewModelState) {
                
            case (.load, .initialized),
                 (.load, .loaded),
                 (.load, .failed):
                return State(viewModel: ProfileViewModel(state: .loading), effect: .load)
                
            case (.load, .loading):
                return noChange // ignore `.load` messages if we're already in a loading state.
                
            case (.loaded(let user), .loading):
                return State(viewModel: ProfileViewModel(state: .loaded(user)), effect: nil)
                
            case (.loaded, _):
                return noChange // `.loaded` command can not be handled from any other view state besides `.loading`.
                
            case (.failed(let error), .loading):
                return State(viewModel: ProfileViewModel(state: .failed(error)), effect: nil)
                
            case (.failed, _):
                return noChange // `.failed` command can not be handled from any other view state besides `.loading`.
            }
        }
    }

}

struct ViewModelReducer {
    enum Command { /* cases */ }
    
    enum Effect {  /* cases */ }
    
    struct State {
        let viewModel: ViewModel
        let effect: Effect?
    }
    
    static func reduce(state: State, command: Command) -> State {
        // Determine a new output State based on each input State & Command combination.
    }
}

final class Interactor {
    enum Command { }
    enum Effect { }
    
    // Inputs
    let commandSink: Signal<Command, NoError>.Observer
    
    // Outputs
    let viewModel: Property<ViewModel>
    let effect: Signal<Effect, NoError>
}


