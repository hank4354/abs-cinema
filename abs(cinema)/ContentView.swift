//
//  ContentView.swift
//  abs(cinema)
//

import SwiftUI

// MARK: - Модели

enum ContentType: String, Codable, CaseIterable, Identifiable {
    case movie = "Фильмы"
    case series = "Сериалы"
    case cartoon = "Мультфильмы"
    var id: String { rawValue }
}

enum WatchStatus: String, Codable, CaseIterable, Identifiable {
    case want = "Хочу посмотреть"
    case watched = "Смотрел"
    case notWant = "Не хочу смотреть"
    var id: String { rawValue }
}

struct ContentItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let year: String
    let rating: Double
    let description: String
    let imageName: String? // имя локального изображения или url
    let type: ContentType
    let duration: Int // длительность в минутах
    let episodesCount: Int? // количество серий для сериалов
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    var totalDuration: Int {
        if type == .series, let episodes = episodesCount {
            return duration * episodes
        }
        return duration
    }
    
    var formattedTotalDuration: String {
        let totalMinutes = totalDuration
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    var imageURL: URL? {
        if let imageName = imageName {
            if imageName.hasPrefix("http") {
                return URL(string: imageName)
            } else {
                return Bundle.main.url(forResource: imageName, withExtension: "jpg", subdirectory: "MovieCovers")
            }
        }
        return nil
    }
    
    var isValidImageURL: Bool {
        if let url = imageURL {
            return url.absoluteString.contains("image.tmdb.org")
        }
        return false
    }
}

// MARK: - ViewModels

class ContentViewModel: ObservableObject {
    @Published var allItems: [ContentItem] = []
    @Published var lists: [WatchStatus: [ContentItem]] = [
        .want: [],
        .notWant: [],
        .watched: []
    ]
    @Published var selectedType: ContentType = .movie
    @Published var currentIndices: [ContentType: Int] = [
        .movie: 0,
        .series: 0,
        .cartoon: 0
    ]

    init() {
        loadMockData()
    }

    func loadMockData() {
        allItems = ContentData.loadMockData()
    }

    func addToList(item: ContentItem, status: WatchStatus) {
        removeFromAllLists(item: item)
        if !lists[status]!.contains(item) {
            lists[status]?.append(item)
        }
    }
    
    func removeFromAllLists(item: ContentItem) {
        for key in lists.keys {
            lists[key] = lists[key]?.filter { $0.id != item.id }
        }
    }
    
    func isInAnyList(item: ContentItem) -> Bool {
        lists.values.flatMap { $0 }.contains(where: { $0.id == item.id })
    }
    
    func updateCurrentIndex(for type: ContentType, index: Int) {
        currentIndices[type] = index
    }
    
    func getCurrentIndex(for type: ContentType) -> Int {
        currentIndices[type] ?? 0
    }
}

class ThemeViewModel: ObservableObject {
    @Published var isDark: Bool = false
    @Published var selectedTab: Int = 0
    @Published var isFirstLaunch: Bool = true
    
    func toggleTheme() {
        isDark.toggle()
        configureTabBar()
    }
    
    func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = isDark ? UIColor(Color(hex: "23232b")) : .systemBackground
        
        // Настройка цвета текста и иконок для неактивных вкладок
        appearance.stackedLayoutAppearance.normal.iconColor = isDark ? .white.withAlphaComponent(0.6) : .darkGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: isDark ? UIColor.white.withAlphaComponent(0.6) : UIColor.darkGray
        ]
        
        // Настройка цвета текста и иконок для активной вкладки
        appearance.stackedLayoutAppearance.selected.iconColor = isDark ? .white : .systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: isDark ? UIColor.white : UIColor.systemBlue
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - SplashView

struct SplashView: View {
    @Binding var isActive: Bool
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            Text("abs(cinema)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.black)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { isActive = false }
            }
        }
    }
}

// MARK: - ThemeSwitcher

struct ThemeSwitcher: View {
    @EnvironmentObject var theme: ThemeViewModel
    var body: some View {
        Button(action: { theme.toggleTheme() }) {
            Image(systemName: theme.isDark ? "moon.fill" : "moon")
                .font(.title2)
                .foregroundColor(theme.isDark ? .white : .black)
                .padding(8)
                .background(Color(.systemGray5).opacity(theme.isDark ? 0.2 : 0.5))
                .clipShape(Circle())
        }
    }
}

// MARK: - StatisticsView

struct StatisticsView: View {
    @EnvironmentObject var vm: ContentViewModel
    @EnvironmentObject var theme: ThemeViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Статистика")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.isDark ? .white : .black)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(ContentType.allCases) { type in
                        StatisticsCard(
                            title: type.rawValue,
                            wantCount: vm.lists[.want]?.filter { $0.type == type }.count ?? 0,
                            watchedCount: vm.lists[.watched]?.filter { $0.type == type }.count ?? 0,
                            notWantCount: vm.lists[.notWant]?.filter { $0.type == type }.count ?? 0,
                            watchedItems: vm.lists[.watched]?.filter { $0.type == type } ?? [],
                            theme: theme
                        )
                    }
                    
                    StatisticsCard(
                        title: "Всего",
                        wantCount: vm.lists[.want]?.count ?? 0,
                        watchedCount: vm.lists[.watched]?.count ?? 0,
                        notWantCount: vm.lists[.notWant]?.count ?? 0,
                        watchedItems: vm.lists[.watched] ?? [],
                        theme: theme
                    )
                }
                .padding(.horizontal, 24)
            }
        }
        .background(theme.isDark ? Color(hex: "23232b") : Color.white)
    }
}

struct StatisticsCard: View {
    let title: String
    let wantCount: Int
    let watchedCount: Int
    let notWantCount: Int
    let watchedItems: [ContentItem]
    @ObservedObject var theme: ThemeViewModel
    
    var totalWatchTime: Int {
        watchedItems.reduce(0) { $0 + $1.totalDuration }
    }
    
    var formattedTotalWatchTime: String {
        let hours = totalWatchTime / 60
        let minutes = totalWatchTime % 60
        if hours > 0 {
            return "\(hours)ч \(minutes)мин"
        } else {
            return "\(minutes)мин"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(theme.isDark ? .white : .black)
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Хочу посмотреть",
                    count: wantCount,
                    color: .green,
                    icon: "eye",
                    theme: theme
                )
                
                StatItem(
                    title: "Просмотрено",
                    count: watchedCount,
                    color: .blue,
                    icon: "eye.fill",
                    theme: theme
                )
                
                StatItem(
                    title: "Не хочу",
                    count: notWantCount,
                    color: .red,
                    icon: "eye.slash",
                    theme: theme
                )
            }
            
            if watchedCount > 0 {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Общее время просмотра: \(formattedTotalWatchTime)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.isDark ? .white.opacity(0.8) : .gray)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(theme.isDark ? Color(hex: "2d2d36") : Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    @ObservedObject var theme: ThemeViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(height: 24)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.isDark ? .white : .black)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(theme.isDark ? .white.opacity(0.7) : .gray)
                .multilineTextAlignment(.center)
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var theme: ThemeViewModel
    @EnvironmentObject var vm: ContentViewModel
    @State private var navType: ContentType? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HStack {
                    Text("Выберите категорию")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.isDark ? .white : .black)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(spacing: 16) {
                    ForEach(ContentType.allCases) { type in
                        NavigationLink(destination: CardSwipeView(type: type), tag: type, selection: $navType) {
                            Button(action: { navType = type }) {
                                HStack {
                                    Image(systemName: type == .movie ? "film" : 
                                                type == .series ? "tv" : "play.tv")
                                        .font(.system(size: 24))
                                        .foregroundColor(theme.isDark ? .white : .black)
                                        .frame(width: 48, height: 48)
                                        .background(theme.isDark ? Color(hex: "2d2d36").opacity(0.5) : Color(.systemGray5))
                                        .clipShape(Circle())
                                    
                                    Text(type.rawValue)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(theme.isDark ? .white : .black)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(theme.isDark ? .white.opacity(0.7) : .black.opacity(0.7))
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 72)
                                .background(theme.isDark ? Color(hex: "2d2d36") : Color(.systemGray6))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(theme.isDark ? Color(hex: "23232b") : Color.white)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - CardSwipeView

struct CardSwipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var vm: ContentViewModel
    @EnvironmentObject var theme: ThemeViewModel
    let type: ContentType
    @State private var offset: CGSize = .zero
    @State private var showDetails = false
    @State private var isSwiping = false
    @State private var rotation: Double = 0

    var filteredItems: [ContentItem] {
        vm.allItems.filter { $0.type == type }
    }
    
    var currentIndex: Int {
        get { vm.getCurrentIndex(for: type) }
        set { vm.updateCurrentIndex(for: type, index: newValue) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(theme.isDark ? .white : .black)
                        .padding(8)
                        .background(Color(.systemGray5).opacity(theme.isDark ? 0.2 : 1))
                        .clipShape(Circle())
                }
                Text(type.rawValue)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.isDark ? .white : .black)
                    .padding(.leading, 8)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer(minLength: 16)
            ZStack {
                if currentIndex < filteredItems.count {
                    let item = filteredItems[currentIndex]
                    
                    CardView(item: item, theme: theme)
                        .offset(offset)
                        .rotationEffect(.degrees(rotationForOffset(offset)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    isSwiping = true
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        let zone = swipeZone(for: offset)
                                        switch zone {
                                        case .right, .topRight:
                                            vm.addToList(item: item, status: .want)
                                        case .left, .topLeft:
                                            vm.addToList(item: item, status: .notWant)
                                        case .down, .downLeft, .downRight:
                                            vm.addToList(item: item, status: .watched)
                                        default:
                                            break // Do nothing on slight swipe or no swipe
                                        }
                                        
                                        // Animate card out based on final swipe direction or return to center
                                        if abs(offset.width) > 100 || abs(offset.height) > 100 { // If swiped far enough
                                            let finalOffset: CGSize
                                            switch zone {
                                            case .right, .topRight: finalOffset = CGSize(width: 500, height: 0)
                                            case .left, .topLeft: finalOffset = CGSize(width: -500, height: 0)
                                            case .down, .downLeft, .downRight: finalOffset = CGSize(width: 0, height: 500)
                                            default: finalOffset = .zero // Should not happen if condition is met
                                            }
                                            offset = finalOffset
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                offset = .zero
                                                vm.updateCurrentIndex(for: type, index: currentIndex + 1)
                                            }
                                        } else { // Return to center if not swiped far enough
                                            offset = .zero
                                        }
                                        isSwiping = false
                                    }
                                }
                        )
                        .onTapGesture {
                            showDetails = true
                        }
                        .sheet(isPresented: $showDetails) {
                            DetailsView(item: item)
                        }
                    
                    // Left hint
                    swipeHintView(
                        text: "Не хочу",
                        systemImage: "eye.slash",
                        color: .red,
                        active: isSwiping && offset.width < -100 && offset.height <= 100
                    )
                    .offset(x: -130)
                    .opacity(isSwiping ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSwiping)
                    
                    // Right hint
                    swipeHintView(
                        text: "Хочу",
                        systemImage: "eye",
                        color: .green,
                        active: isSwiping && offset.width > 100 && offset.height <= 100
                    )
                    .offset(x: 130)
                    .opacity(isSwiping ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSwiping)
                    
                    // Bottom hint
                    swipeHintView(
                        text: "Смотрел",
                        systemImage: "eye.fill",
                        color: .blue,
                        active: isSwiping && offset.height > 100
                    )
                    .offset(y: 280)
                    .opacity(isSwiping ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSwiping)
                } else {
                    Text("Больше нет карточек")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .padding(.top, 80)
                }
            }
            Spacer()
        }
        .background(theme.isDark ? Color(hex: "23232b") : Color.white)
        .navigationBarHidden(true)
    }

    enum SwipeZone { case left, right, down, downLeft, downRight, topLeft, topRight, none }
    func swipeZone(for offset: CGSize) -> SwipeZone {
        let threshold: CGFloat = 100
        let verticalThreshold: CGFloat = 80
        
        if offset.width > threshold && offset.height > verticalThreshold { return .downRight }
        if offset.width < -threshold && offset.height > verticalThreshold { return .downLeft }
        if offset.width > threshold && offset.height < -verticalThreshold { return .topRight }
        if offset.width < -threshold && offset.height < -verticalThreshold { return .topLeft }
        if offset.width > threshold { return .right }
        if offset.width < -threshold { return .left }
        if offset.height > threshold { return .down }
        return .none
    }
    func swipeHintView(text: String, systemImage: String, color: Color, active: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(active ? color : (theme.isDark ? Color(.systemGray3) : Color(.systemGray3)))
        .frame(width: text == "Смотрел" ? 80 : 70)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(active ? (theme.isDark ? Color(hex: "2d2d36") : Color.white) : (theme.isDark ? Color(hex: "2d2d36").opacity(0.5) : Color(.systemGray6)))
        .cornerRadius(14)
        .shadow(color: active ? color.opacity(0.15) : .clear, radius: 6, x: 0, y: 2)
    }
    mutating func nextCard() {
        offset = .zero
        currentIndex += 1
    }
    func rotationForOffset(_ offset: CGSize) -> Double {
        if abs(offset.width) > abs(offset.height) {
            return Double(offset.width / 15)
        } else if offset.height > 0 {
            return Double(offset.width / 30)
        } else if offset.height < 0 {
            return Double(offset.width / 30)
        }
        return 0
    }
}

struct CardView: View {
    let item: ContentItem
    @ObservedObject var theme: ThemeViewModel
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.isDark ? Color(hex: "3b3b45") : Color(.systemGray5))
                .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
            
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    if isLoading {
                        ProgressView()
                    } else if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 390)
                            .clipped()
                    } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemGray4))
                        .frame(height: 390)
                        .overlay(
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        )
                    }
                    
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)]), startPoint: .center, endPoint: .bottom)
                        .frame(height: 300)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.title).bold()
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text(String(format: "%.1f", item.rating))
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("• \(item.year)")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                            Text("• \(item.formattedDuration)")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                }
                .cornerRadius(24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Описание")
                        .font(.headline)
                        .foregroundColor(theme.isDark ? .white : .black)
                    Text(item.description)
                        .font(.system(size: 14))
                        .foregroundColor(theme.isDark ? .white.opacity(0.8) : .gray)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
        }
        .frame(width: 340, height: 500)
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .onAppear {
            loadImage()
        }
        .onChange(of: item) { oldItem, newItem in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL = item.imageURL else {
            print("Error loading image: No image URL available for: \(item.title)")
            return
        }
        
        isLoading = true
        loadError = false
        
        print("Loading image for: \(item.title)")
        print("Image URL: \(imageURL.absoluteString)")
        
        if imageURL.isFileURL {
            print("Loading local file")
            if let data = try? Data(contentsOf: imageURL),
               let loadedImage = UIImage(data: data) {
                print("Successfully loaded local image")
                self.image = loadedImage
            } else {
                print("Failed to load local image")
                loadError = true
            }
            isLoading = false
        } else {
            print("Loading remote image")
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("Error loading remote image: \(error.localizedDescription)")
                        loadError = true
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                         print("HTTP Status Code: \(httpResponse.statusCode)")
                    }
                    
                    if let data = data, let loadedImage = UIImage(data: data) {
                        print("Successfully loaded remote image")
                        self.image = loadedImage
                    } else {
                        print("Failed to create image from data")
                        loadError = true
                    }
                }
            }.resume()
        }
    }
}

// MARK: - ListsView

struct ListsView: View {
    @EnvironmentObject var vm: ContentViewModel
    @EnvironmentObject var theme: ThemeViewModel
    @State private var selectedType: ContentType = .movie
    @State private var selectedStatus: WatchStatus = .want
    @State private var sortByRating = false
    @State private var sortByYear = false
    @State private var showSortSheet = false
    @State private var selectedItem: ContentItem? = nil

    var filteredList: [ContentItem] {
        let list = vm.lists[selectedStatus]?.filter { $0.type == selectedType } ?? []
        if sortByRating {
            return list.sorted { $0.rating > $1.rating }
        } else if sortByYear {
            return list.sorted { $0.year > $1.year }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Мои списки")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.isDark ? .white : .black)
                Spacer()
                Button(action: { showSortSheet = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 20))
                        .foregroundColor(theme.isDark ? .white : .blue)
                        .padding(8)
                        .background(Color(.systemGray6).opacity(theme.isDark ? 0.2 : 1))
                        .clipShape(Circle())
                }
                .actionSheet(isPresented: $showSortSheet) {
                    ActionSheet(title: Text("Сортировка"), buttons: [
                        .default(Text("По рейтингу")) { sortByRating = true; sortByYear = false },
                        .default(Text("По году")) { sortByYear = true; sortByRating = false },
                        .cancel(Text("Сбросить")) { sortByRating = false; sortByYear = false }
                    ])
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            HStack(spacing: 8) {
                ForEach(ContentType.allCases) { type in
                    Button(action: { selectedType = type }) {
                        Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedType == type ? 
                                (theme.isDark ? Color(hex: "3b3b45") : Color(.systemGray5)) : 
                                (theme.isDark ? Color(hex: "2d2d36").opacity(0.3) : Color(.systemGray6)))
                            .foregroundColor(selectedType == type ? 
                                (theme.isDark ? .white : .black) : 
                                (theme.isDark ? .white.opacity(0.5) : .gray))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            
            List {
                ForEach(filteredList) { item in
                    ListCardView(item: item, status: selectedStatus)
                        .onTapGesture {
                            selectedItem = item
                        }
                        .environmentObject(theme)
                        .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.bottom, 0)
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(WatchStatus.allCases) { status in
                    Button(action: { selectedStatus = status }) {
                        VStack(spacing: 2) {
                            Image(systemName: status == .want ? "heart.fill" : 
                                          status == .notWant ? "eye.slash" : "eye.fill")
                                .font(.system(size: 20))
                            Text(status.rawValue)
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundColor(selectedStatus == status ? 
                            (status == .want ? .green : 
                             status == .notWant ? .red : 
                             status == .watched ? .blue : .gray) : (theme.isDark ? .white.opacity(0.7) : .gray))
                    }
                }
            }
            .background(theme.isDark ? Color(hex: "23232b") : Color.white)
        }
        .background(theme.isDark ? Color(hex: "23232b") : Color.white)
        .sheet(item: $selectedItem) { item in
            DetailsView(item: item)
        }
    }
}

struct ListCardView: View {
    let item: ContentItem
    let status: WatchStatus
    @EnvironmentObject var theme: ThemeViewModel
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError = false
    
    @EnvironmentObject var vm: ContentViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.isDark ? Color(hex: "3b3b45") : Color(.systemGray5))
                .frame(width: 48, height: 68)
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                        } else if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: loadError ? "exclamationmark.triangle" : "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(theme.isDark ? .gray.opacity(0.6) : .gray)
                        }
                    }
                )
                .clipped()
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(theme.isDark ? .white : .black)
                Text("\(item.year)")
                    .font(.subheadline)
                    .foregroundColor(theme.isDark ? .white.opacity(0.7) : .gray)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text(String(format: "%.1f", item.rating))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.isDark ? Color(hex: "2d2d36") : Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            loadImage()
        }
        .swipeActions(edge: .trailing) {
            switch status {
            case .notWant:
                Button {
                    vm.addToList(item: item, status: .watched)
                } label: {
                    Label("Просмотрено", systemImage: "eye.fill")
                }
                .tint(.blue)
            case .watched:
                Button {
                    vm.addToList(item: item, status: .want)
                } label: {
                    Label("Хочу посмотреть", systemImage: "eye")
                }
                .tint(.green)
            case .want:
                Button {
                    vm.addToList(item: item, status: .watched)
                } label: {
                    Label("Просмотрено", systemImage: "eye.fill")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .leading) {
            switch status {
            case .notWant:
                Button {
                    vm.addToList(item: item, status: .want)
                } label: {
                    Label("Хочу посмотреть", systemImage: "eye")
                }
                .tint(.green)
            case .want:
                Button {
                    vm.addToList(item: item, status: .notWant)
                } label: {
                    Label("Не хочу смотреть", systemImage: "eye.slash")
                }
                .tint(.red)
            case .watched:
                Button {
                    vm.addToList(item: item, status: .notWant)
                } label: {
                    Label("Не хочу смотреть", systemImage: "eye.slash")
                }
                .tint(.red)
            }
        }
    }
    
    private func loadImage() {
        guard let imageURL = item.imageURL else {
            print("ListCardView: No image URL available for: \(item.title)")
            return
        }
        
        isLoading = true
        loadError = false
        
        print("ListCardView: Loading image for: \(item.title)")
        print("ListCardView: Image URL: \(imageURL.absoluteString)")
        
        if imageURL.isFileURL {
            print("ListCardView: Loading local file")
            if let data = try? Data(contentsOf: imageURL),
               let loadedImage = UIImage(data: data) {
                print("ListCardView: Successfully loaded local image")
                self.image = loadedImage
            } else {
                print("ListCardView: Failed to load local image")
                loadError = true
            }
            isLoading = false
        } else {
            print("ListCardView: Loading remote image")
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("ListCardView: Error loading remote image: \(error.localizedDescription)")
                        loadError = true
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                         print("ListCardView: HTTP Status Code: \(httpResponse.statusCode)")
                    }
                    
                    if let data = data, let loadedImage = UIImage(data: data) {
                        print("ListCardView: Successfully loaded remote image")
                        self.image = loadedImage
                    } else {
                        print("ListCardView: Failed to create image from data")
                        loadError = true
                    }
                }
            }.resume()
        }
    }
}

// MARK: - DetailsView

struct DetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var theme: ThemeViewModel
    let item: ContentItem
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(theme.isDark ? .white : .black)
                        .padding(8)
                        .background(Color(.systemGray5).opacity(theme.isDark ? 0.2 : 1))
                        .clipShape(Circle())
                }
                Text(item.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.isDark ? .white : .black)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemGray4))
                        .frame(height: 250)
                        
                        Group {
                            if isLoading {
                                ProgressView()
                            } else if let image = image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: loadError ? "exclamationmark.triangle" : "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .clipped()
                    .cornerRadius(24)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Text(String(format: "%.1f", item.rating))
                                    .font(.title2)
                                    .foregroundColor(theme.isDark ? .white : .black)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("• \(item.year)")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                Text("• \(item.formattedDuration)")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Жанр")
                                .font(.headline)
                                .foregroundColor(theme.isDark ? .white : .black)
                            Text(ContentData.getGenre(for: item))
                                .font(.body)
                                .foregroundColor(theme.isDark ? .white.opacity(0.8) : .gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Сюжет")
                                .font(.headline)
                                .foregroundColor(theme.isDark ? .white : .black)
                            Text(ContentData.getDetailedPlot(for: item))
                                .font(.body)
                                .foregroundColor(theme.isDark ? .white.opacity(0.8) : .gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.top, 24)
            }
            Spacer()
        }
        .background(theme.isDark ? Color(hex: "23232b") : Color(.systemBackground))
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL = item.imageURL else {
            print("DetailsView: No image URL available for: \(item.title)")
            return
        }
        
        isLoading = true
        loadError = false
        
        print("DetailsView: Loading image for: \(item.title)")
        print("DetailsView: Image URL: \(imageURL.absoluteString)")
        
        if imageURL.isFileURL {
            print("DetailsView: Loading local file")
            if let data = try? Data(contentsOf: imageURL),
               let loadedImage = UIImage(data: data) {
                print("DetailsView: Successfully loaded local image")
                self.image = loadedImage
            } else {
                print("DetailsView: Failed to load local image")
                loadError = true
            }
            isLoading = false
        } else {
            print("DetailsView: Loading remote image")
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("DetailsView: Error loading remote image: \(error.localizedDescription)")
                        loadError = true
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                         print("DetailsView: HTTP Status Code: \(httpResponse.statusCode)")
                    }
                    
                    if let data = data, let loadedImage = UIImage(data: data) {
                        print("DetailsView: Successfully loaded remote image")
                        self.image = loadedImage
                    } else {
                        print("DetailsView: Failed to create image from data")
                        loadError = true
                    }
                }
            }.resume()
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var theme: ThemeViewModel
    @State private var notificationsEnabled = true
    @State private var showConfirmation = false
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Настройки")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.isDark ? .white : .black)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Внешний вид
                    SettingsCard(title: "Внешний вид") {
                        Toggle("Темная тема", isOn: $theme.isDark)
                            .tint(.blue)
                            .foregroundColor(theme.isDark ? .white : .black)
                    }
                    
                    // Уведомления
                    SettingsCard(title: "Уведомления") {
                        Toggle("Включить уведомления", isOn: $notificationsEnabled)
                            .tint(.blue)
                            .foregroundColor(theme.isDark ? .white : .black)
                    }
                    
                    
                    // Данные
                    SettingsCard(title: "Данные") {
                        Button(action: { showConfirmation = true }) {
                            HStack {
                                Text("Очистить все данные")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // О приложении
                    SettingsCard(title: "О приложении") {
                        HStack {
                            Text("Версия")
                                .foregroundColor(theme.isDark ? .white : .black)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(theme.isDark ? .white.opacity(0.7) : .gray)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .background(theme.isDark ? Color(hex: "23232b") : Color.white)
        .alert("Очистить данные", isPresented: $showConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Очистить", role: .destructive) {
                // Здесь будет логика очистки данных
            }
        } message: {
            Text("Вы уверены, что хотите удалить все данные? Это действие нельзя отменить.")
        }
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    @EnvironmentObject var theme: ThemeViewModel
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(theme.isDark ? .white : .black)
            
            content
        }
        .padding(20)
        .background(theme.isDark ? Color(hex: "2d2d36") : Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - ContentView (App Root)

struct ContentView: View {
    @StateObject private var contentVM = ContentViewModel()
    @StateObject private var themeVM = ThemeViewModel()
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            if isActive {
                SplashView(isActive: $isActive)
            } else {
                if themeVM.isFirstLaunch {
                    OnboardingView(isShowingOnboarding: $themeVM.isFirstLaunch)
                } else {
                    TabView(selection: $themeVM.selectedTab) {
                        // Главная вкладка
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Главная")
                            }
                            .tag(0)
                        
                        // Вкладка списков
                        ListsView()
                            .tabItem {
                                Image(systemName: "list.bullet")
                                Text("Списки")
                            }
                            .tag(1)
                        
                        // Вкладка статистики
                        StatisticsView()
                            .tabItem {
                                Image(systemName: "chart.bar.fill")
                                Text("Статистика")
                            }
                            .tag(2)
                        
                        // Вкладка настроек
                        SettingsView()
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Настройки")
                            }
                            .tag(3)
                    }
                    .tint(themeVM.isDark ? .white : .blue)
                    .toolbarBackground(themeVM.isDark ? Color(hex: "23232b") : .white, for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .onAppear {
                        // Настройка цветов TabBar
                        let appearance = UITabBarAppearance()
                        appearance.configureWithOpaqueBackground()
                        appearance.backgroundColor = themeVM.isDark ? UIColor(Color(hex: "23232b")) : .systemBackground
                        
                        // Настройка цвета текста и иконок для неактивных вкладок
                        appearance.stackedLayoutAppearance.normal.iconColor = themeVM.isDark ? .white.withAlphaComponent(0.6) : .darkGray
                        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                            .foregroundColor: themeVM.isDark ? UIColor.white.withAlphaComponent(0.6) : UIColor.darkGray
                        ]
                        
                        // Настройка цвета текста и иконок для активной вкладки
                        appearance.stackedLayoutAppearance.selected.iconColor = themeVM.isDark ? .white : .systemBlue
                        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                            .foregroundColor: themeVM.isDark ? UIColor.white : UIColor.systemBlue
                        ]
                        
                        UITabBar.appearance().standardAppearance = appearance
                        UITabBar.appearance().scrollEdgeAppearance = appearance
                    }
                }
            }
        }
        .environmentObject(contentVM)
        .environmentObject(themeVM)
    }
}

#Preview {
    ContentView()
}

// Вспомогательный экстеншн для цвета по hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
