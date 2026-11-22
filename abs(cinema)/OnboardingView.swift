import SwiftUI

struct OnboardingView: View {
    @Binding var isShowingOnboarding: Bool
    @State private var currentPage = 0
    @State private var isTransitioning = false
    
    // Константы для отступов
    private let imageBottomPadding: CGFloat = 40
    private let titleBottomPadding: CGFloat = 2
    private let textTopPadding: CGFloat = 10
    private let textBottomPadding: CGFloat = 40
    private let swipeViewTopPadding: CGFloat = -20
    private let swipeViewBottomPadding: CGFloat = 40
    
    let onboardingPages = [
        OnboardingPage(
            title: "Добро пожаловать!",
            description: "Давайте познакомимся с основными функциями приложения abs(cinema)",
            imageName: "welcome"
        ),
        OnboardingPage(
            title: "Свайпы",
            description: "Cортируйте фильмы по спискам с помощью простых жестов",
            imageName: "swipe"
        ),
        OnboardingPage(
            title: "Вкладки",
            description: "Переходите между вкладками через удобное меню в нижней части экрана",
            imageName: "Vkladki"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            if index == 1 {
                                SwipeOnboardingView()
                                    .frame(height: 250)
                                    .padding(.top, swipeViewTopPadding)
                                    .padding(.bottom, swipeViewBottomPadding)
                                    .padding(.top, 80)
                            } else if index == 2 {
                                TabBarIconsView()
                                    .frame(height: 250)
                                    .padding(.top, swipeViewTopPadding)
                                    .padding(.bottom, swipeViewBottomPadding)
                                    .padding(.top, 120)
                            } else {
                                Image(onboardingPages[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .cornerRadius(20)
                                    .padding(.bottom, imageBottomPadding)
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                Text(onboardingPages[index].title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.horizontal)
                                    .padding(.bottom, titleBottomPadding)
                                
                                Text(onboardingPages[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.top, textTopPadding)
                                    .padding(.bottom, textBottomPadding)
                            }
                            .padding(.bottom, 80)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                
                Button(action: {
                    if currentPage < onboardingPages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isTransitioning = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isShowingOnboarding = false
                        }
                    }
                }) {
                    Text(currentPage < onboardingPages.count - 1 ? "Далее" : "Начать")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .opacity(isTransitioning ? 0 : 1)
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct SwipeOnboardingView: View {
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var currentSwipe: SwipeDirection? = nil
    @State private var isAnimating = false
    @State private var animationTask: Task<Void, Never>?
    
    enum SwipeDirection { case left, right, down }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 180, height: 250)
                .offset(cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .animation(.easeInOut(duration: 1.0), value: cardOffset)
                .animation(.easeInOut(duration: 1.0), value: cardRotation)
            
            SwipeHintOverlayView(currentSwipe: currentSwipe)
                .frame(width: 300, height: 350)
        }
        .frame(height: 300)
        .onAppear {
            isAnimating = true
            startSwipeAnimation()
        }
        .onDisappear {
            isAnimating = false
            animationTask?.cancel()
        }
    }
    
    func startSwipeAnimation() {
        guard isAnimating else { return }
        
        animationTask?.cancel()
        animationTask = Task {
            while isAnimating {
                // Right swipe
                await animateSwipe(direction: .right, offset: CGSize(width: 100, height: 0), rotation: 10)
                if !isAnimating { break }
                
                // Reset
                await animateReset()
                if !isAnimating { break }
                
                // Left swipe
                await animateSwipe(direction: .left, offset: CGSize(width: -100, height: 0), rotation: -10)
                if !isAnimating { break }
                
                // Reset
                await animateReset()
                if !isAnimating { break }
                
                // Down swipe
                await animateSwipe(direction: .down, offset: CGSize(width: 0, height: 150), rotation: 0)
                if !isAnimating { break }
                
                // Reset
                await animateReset()
                if !isAnimating { break }
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
    
    private func animateSwipe(direction: SwipeDirection, offset: CGSize, rotation: Double) async {
        withAnimation(.easeInOut(duration: 1.0)) {
            currentSwipe = direction
            cardOffset = offset
            cardRotation = rotation
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    private func animateReset() async {
        withAnimation(.easeInOut(duration: 1.0)) {
            currentSwipe = nil
            cardOffset = .zero
            cardRotation = 0
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

struct SwipeHintOverlayView: View {
    let currentSwipe: SwipeOnboardingView.SwipeDirection?
    
    var body: some View {
        ZStack {
            SwipeHintView(text: "Не хочу смотреть", systemImage: "arrow.left", color: .red, isActive: currentSwipe == .left)
                .offset(x: -120, y: -20)
            
            SwipeHintView(text: "Хочу посмотреть", systemImage: "arrow.right", color: .green, isActive: currentSwipe == .right)
                .offset(x: 120, y: -20)
            
            SwipeHintView(text: "Смотрел", systemImage: "arrow.down", color: .blue, isActive: currentSwipe == .down)
                .offset(y: 150)
        }
    }
}

struct SwipeHintView: View {
    let text: String
    let systemImage: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(isActive ? color : .gray.opacity(0.7))
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(isActive ? 0.9 : 0.3))
        .cornerRadius(14)
        .shadow(color: isActive ? color.opacity(0.2) : .clear, radius: 6, x: 0, y: 2)
    }
}

struct TabBarIconsView: View {
    @State private var selectedTab: Int = 0
    @State private var isAnimating = false
    @State private var showDescription = false
    let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    let tabDescriptions = [
        "Главная — новые фильмы и персональные рекомендации на основе ваших предпочтений",
        "Списки — ваши сохраненные фильмы, которые вы хотите посмотреть позже",
        "Статистика — история просмотров и ваши любимые жанры",
        "Настройки — персонализация приложения и управление аккаунтом"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                ForEach(0..<4) { index in
                    VStack(spacing: 8) {
                        Image(systemName: getIconName(for: index))
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == index ? .blue : .white)
                            .scaleEffect(selectedTab == index ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        Text(getTabName(for: index))
                            .font(.system(size: 12))
                            .foregroundColor(selectedTab == index ? .blue : .white)
                    }
                }
            }
            
            if showDescription {
                Text(tabDescriptions[selectedTab])
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5).combined(with: .opacity),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal)
        .onAppear {
            isAnimating = true
            showDescription = true
        }
        .onReceive(timer) { _ in
            if isAnimating {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDescription = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = (selectedTab + 1) % 4
                        showDescription = true
                    }
                }
            }
        }
    }
    
    private func getIconName(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "list.bullet"
        case 2: return "chart.bar.fill"
        case 3: return "gearshape.fill"
        default: return ""
        }
    }
    
    private func getTabName(for index: Int) -> String {
        switch index {
        case 0: return "Главная"
        case 1: return "Списки"
        case 2: return "Статистика"
        case 3: return "Настройки"
        default: return ""
        }
    }
}

#Preview {
    OnboardingView(isShowingOnboarding: .constant(true))
} 
