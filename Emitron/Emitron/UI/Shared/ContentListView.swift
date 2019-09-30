/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

private struct Layout {
  static let sidePadding: CGFloat = 18
  static let heightDivisor: CGFloat = 3
}

enum ContentScreen {
  case library, downloads, myTutorials, tips
  
  var titleMessage: String {
    switch self {
    // TODO: maybe this should be a func instead & we can pass in the actual search criteria here
    case .library: return "We couldn't find anything meeting the search criteria."
    case .downloads: return "You haven't downloaded any tutorials yet."
    case .myTutorials: return "You haven't started any tutorials yet."
    case .tips: return "Swipe left to delete a download."
    }
  }
  
  var detailMesage: String? {
    switch self {
    case .library: return "Try removing some filters."
    case .tips: return "Swipe on your downloads to remove them."
    default: return nil
    }
  }
  
  var buttonText: String? {
    switch self {
    case .downloads: return "Explore Tutorials"
    case .tips: return "Got it!"
    default: return nil
    }
  }
  
  var buttonIconName: String? {
    switch self {
    case .downloads, .tips: return "arrowGreen"
    case .myTutorials: return "arrowRed"
    default: return nil
    }
  }
  
  var buttonColor: Color? {
    switch self {
    case .downloads, .tips: return .appGreen
    case .myTutorials: return .copper
    default: return nil
    }
  }
}

struct ContentListView: View {
  
  @State var showHudView: Bool = false
  @State var showSuccess: Bool = false
  @State var contentScreen: ContentScreen
  @State var isPresenting: Bool = false
  var contents: [ContentSummaryModel] = []
  var bgColor: Color
  @State var selectedMC: ContentSummaryMC?
  @EnvironmentObject var contentsMC: ContentsMC
  var headerView: AnyView?
  var dataState: DataState
  var totalContentNum: Int
  var callback: ((DownloadsAction, ContentSummaryModel) -> Void)?
  
  var body: some View {
//    ZStack(alignment: .bottom) {
//      contentView
//
//      if showHudView {
//        createHudView()
//          .animation(.spring())
//      }
//    }
    contentView
  }
  
  private var listView: some View {
    List {
      if headerView != nil {
        Section(header: headerView) {
          if contentScreen == .downloads {
            cardsTableViewWithDelete
          } else {
            cardTableNavView
          }
          loadMoreView
        }.listRowInsets(EdgeInsets())
      } else {
        if contentScreen == .downloads {
          cardsTableViewWithDelete
        } else {
          cardTableNavView
        }
        loadMoreView
      }
    }
  }
  
  private var loadMoreView: AnyView? {
    if totalContentNum > contents.count {
      return AnyView(Text("Loading...")
        .onAppear {
          self.contentsMC.loadMore()
      })
    } else {
      return nil
    }
  }
  
  private var contentView: AnyView {
    switch dataState {
    case .initial,
         .loading where contents.isEmpty:
      return AnyView(loadingView)
    case .hasData where contents.isEmpty:
      return AnyView(emptyView)
    case .hasData,
         .failed,
         .loading where !contents.isEmpty:
      return AnyView(listView)
    default:
      return AnyView(emptyView)
    }
  }
  
  private var cardTableNavView: some View {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser
    
    return
      ForEach(contents, id: \.id) { partialContent in
        
        NavigationLink(destination:
          ContentListingView(content: partialContent, callback: { content in
            self.callback?(.save, ContentSummaryModel(contentDetails: content))
          }, user: user!))
        {
          self.cardView(content: partialContent, onRightTap: { success in
            self.callback?(.save, partialContent)
          })
            .padding([.leading], 20)
            .padding([.top, .bottom], 10)
        }
      }
      .listRowBackground(self.bgColor)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
      .background(self.bgColor)
  }
  
  //TODO: Definitely not the cleanest solution to have almost a duplicate of the above variable, but couldn't find a better one
  private var cardsTableViewWithDelete: some View {
    let guardpost = Guardpost.current
    let user = guardpost.currentUser
    
    return
      ForEach(contents, id: \.id) { partialContent in
        
        NavigationLink(destination:
          ContentListingView(content: partialContent, callback: { content in
            self.callback?(.save, ContentSummaryModel(contentDetails: content))
          }, user: user!))
        {
          self.cardView(content: partialContent, onRightTap: { success in
            self.callback?(.save, partialContent)
          })
            .padding([.leading], 20)
            .padding([.top, .bottom], 10)
        }
      }
      .onDelete(perform: self.delete)
      .listRowBackground(self.bgColor)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
      .background(self.bgColor)
  }
  
  private func cardView(content: ContentSummaryModel, onRightTap: ((Bool) -> Void)?) -> some View {
    let viewModel = CardViewModel.transform(content, cardViewType: .default)
    
    return CardView(model: viewModel,
                    contentScreen: contentScreen,
                    onRightIconTap: onRightTap).environmentObject(DataManager.current!.downloadsMC)
  }
  
  private var emptyView: some View {
    VStack {
      headerView
      
      Spacer()
      
      Text(contentScreen.titleMessage)
        .font(.uiTitle2)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)
        .padding([.leading, .trailing, .bottom], 20)
      
      Text(contentScreen.detailMesage ?? "")
        .font(.uiLabel)
        .foregroundColor(.battleshipGrey)
      
      Spacer()
    }
  }
  
  private var loadingView: some View {
    VStack {
      headerView
      
      Spacer()
      
      Text("Loading...")
        .font(.uiTitle2)
        .foregroundColor(.appBlack)
        .multilineTextAlignment(.center)
      
      Spacer()
    }
  }
  
  private func loadMoreContents() {
    contentsMC.loadMore()
  }
  
  private func createHudView() -> some View {
    let option: HudOption = showSuccess ? .success : .error
    return HudView(option: option) {
      self.showHudView = false
    }
  }
  
  func delete(at offsets: IndexSet) {
    guard let index = offsets.first else { return }
    DispatchQueue.main.async {
      let content = self.contents[index]
      self.callback?(.delete, content)
    }
  }
  
  mutating func updateContents(with newContents: [ContentSummaryModel]) {
    self.contents = newContents
  }
}

#if DEBUG
struct ContentListView_Previews: PreviewProvider {
  static var previews: some View {
    return ContentListView(contentScreen: .library, contents: [], bgColor: .paleGrey, dataState: .hasData, totalContentNum: 5)
  }
}
#endif
