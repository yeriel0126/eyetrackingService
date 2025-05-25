import SwiftUI

struct PreferenceRatingStepperView: View {
    let projectName: String
    let perfumes: [Perfume]
    
    @State private var currentIndex: Int = 0
    @State private var ratings: [UUID: Int] = [:]
    @State private var navigateToFinal = false
    @State private var showScentGuide = false
    @State private var isLoading = false
    @State private var error: Error?
    @EnvironmentObject var projectStore: ProjectStore

    let emojiMap: [Int: String] = [
        1: "😖", 2: "😕", 3: "😐", 4: "🙂", 5: "😄"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                if currentIndex < perfumes.count {
                    let perfume = perfumes[currentIndex]
                    
                    RecommendationCardView(perfume: perfume, matchScore: Int.random(in: 80...95))
                        .padding(.top)
                    
                    Text("이 향수는 어땠나요?")
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    Text("향조 구성을 보고 이 향수에 대한 선호도를 평가해주세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Emoji rating
                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { value in
                            Button(action: {
                                ratings[perfume.id] = value
                            }) {
                                Text(emojiMap[value]!)
                                    .font(.system(size: 36))
                                    .opacity(ratings[perfume.id] == value ? 1.0 : 0.5)
                                    .scaleEffect(ratings[perfume.id] == value ? 1.2 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    Button(action: {
                        if ratings[perfume.id] != nil {
                            currentIndex += 1
                        }
                    }) {
                        Text("다음")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ratings[perfume.id] == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                    }
                    .disabled(ratings[perfume.id] == nil)
                    
                } else {
                    Text("모든 향수를 평가했어요!")
                        .font(.headline)
                    
                    if isLoading {
                        ProgressView("평가 결과를 저장하는 중...")
                    } else {
                        Button("최종 추천 보기") {
                            Task {
                                await submitRatings()
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    if let error = error {
                        Text(error.localizedDescription)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                }
            }
            .padding()
            .navigationTitle("선호도 평가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showScentGuide = true
                    }) {
                        Text("노트 가이드")
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToFinal) {
                FinalRecommendationView(
                    projectName: projectName,
                    preferenceRatings: ratings
                )
                .environmentObject(projectStore)
            }
            .sheet(isPresented: $showScentGuide) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        Text("향조 가이드")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 8)
                        
                        // 향조 계열 설명
                        VStack(alignment: .leading, spacing: 24) {
                            Text("향조 계열")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Group {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🌸 플로럴 (Floral)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("부드럽고 여성스러운 꽃 향기. 봄에 어울리는 화사한 느낌.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: rose, jasmine, peony, lily, freesia, violet, magnolia, cherry blossom")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🌳 우디 (Woody)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.brown)
                                    Text("따뜻하고 고요한 나무 향. 고급스럽고 안정적인 인상을 줍니다.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: sandalwood, cedar, vetiver, patchouli, oak, pine, guaiac wood, cypress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🍋 시트러스 (Citrus)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.orange)
                                    Text("상쾌하고 가벼운 과일 향. 여름이나 데일리 향수로 적합합니다.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: bergamot, lemon, lime, grapefruit, yuzu, mandarin orange, orange zest, citron")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🧂 오리엔탈 / 스파이시 (Oriental / Spicy)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.purple)
                                    Text("이국적이고 따뜻한 느낌. 무게감 있고 관능적인 향.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: vanilla, amber, cinnamon, clove, nutmeg, incense, myrrh, cardamom")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🍬 구르망 (Gourmand)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.pink)
                                    Text("달콤하고 먹음직스러운 향. 디저트나 과자 같은 느낌.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: tonka bean, caramel, chocolate, honey, praline, marshmallow, milk, sugar")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🌿 허벌 / 그린 (Herbal / Green)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.green)
                                    Text("자연적인 풀내음과 허브 향. 맑고 건강한 느낌을 줍니다.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: basil, mint, tea, fig leaf, grass, green tea, galbanum, green leaves")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🍓 프루티 (Fruity)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.red)
                                    Text("달콤하거나 상큼한 과일 향. 활기차고 캐주얼한 느낌.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: apple, pear, peach, plum, blackberry, strawberry, melon, grape")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🌊 아쿠아틱 (Aquatic / Ozonic)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.cyan)
                                    Text("바다나 비, 공기 같은 깨끗하고 시원한 향.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: marine, sea breeze, ozonic, water lily, rain, aqua, cool water")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🐄 머스크 / 파우더리 (Musk / Powdery)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.gray)
                                    Text("깨끗하고 포근한 느낌. 섬유유연제, 파우더, 비누 느낌.")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text("예시: musk, white musk, baby powder, iris, clean linen, rice powder, violet leaf")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 개별 향조 설명
                        VStack(alignment: .leading, spacing: 24) {
                            Text("개별 향조 설명")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Group {
                                Text("• Bergamot: 상큼하고 시트러스한 향으로 향수에 생기를 부여함")
                                Text("• Cedar: 건조하고 우디한 느낌으로 베이스 노트에 자주 사용")
                                Text("• Clary Sage: 허브 향으로 상쾌하고 맑은 인상을 줌")
                                Text("• Cocoa: 달콤하고 깊은 초콜릿 향")
                                Text("• Coriander: 스파이시하면서 따뜻한 향")
                                Text("• Hibiscus: 화사하고 꽃다운 향으로 여성스러운 분위기 연출")
                                Text("• Incense: 신비롭고 묵직한 향으로 동양적인 느낌을 줌")
                                Text("• Iris: 가볍고 파우더리한 꽃향기")
                                Text("• Jasmine: 풍성하고 달콤한 플로럴 향")
                                Text("• Jasmine Tea: 섬세하고 차분한 플로럴 향")
                                Text("• Labdanum: 짙고 점성 있는 수지 향으로 무게감을 줌")
                                Text("• Madagascar Vanilla: 부드럽고 크리미한 고급 바닐라 향")
                                Text("• Mint And Wood Moss: 시원하고 자연적인 허브향과 이끼향의 조화")
                                Text("• Moss And Rippled Sand Accord: 짙은 흙과 이끼의 향이 모래의 잔향과 섞인 느낌")
                                Text("• Mother Of Pearl Hibiscus And Woods: 진주빛 꽃과 나무가 섞인 독특하고 고급스러운 향")
                                Text("• Musk: 동물성 느낌의 따뜻하고 감각적인 향")
                                Text("• Nutmeg: 매콤하고 달콤한 향을 동시에 주는 향신료 계열")
                                Text("• Oakmoss: 짙고 습한 이끼 향으로 그린한 베이스 노트")
                                Text("• Olibanum: 신성한 느낌의 수지 향, 깊고 영적인 분위기를 줌")
                                Text("• Patchouli: 어두운 흙내음과 따뜻함이 조화를 이루는 향")
                                Text("• Rose: 클래식하고 로맨틱한 플로럴 향")
                                Text("• Saffron: 스파이시하고 금속적인 느낌의 중성적 향")
                                Text("• Sandalwood: 부드럽고 따뜻한 나무 향, 베이스 노트의 대표격")
                                Text("• Star Anise: 달콤하고 매콤한 별 모양 향신료")
                                Text("• Tangerine: 상큼하고 과즙 가득한 감귤류 향")
                                Text("• Tonka Bean: 달콤하고 따뜻한 콩 향, 바닐라와 비슷하지만 더 고소함")
                                Text("• Vanilla: 전형적인 달콤한 바닐라 향")
                                Text("• Vetiver: 짙고 드라이한 흙 향으로 우디함 강조")
                                Text("• Vetiver And Cedar: 우디한 느낌과 진한 베이스를 함께 제공")
                                Text("• Violet Leaf: 풀잎처럼 풋풋하고 녹음이 짙은 향")
                                Text("• White Flowers: 깨끗하고 섬세한 꽃향기")
                                Text("• Agarwood: 짙고 깊은 오리엔탈 우드 향")
                                Text("• Amber: 따뜻하고 풍부한 레진 계열의 향")
                                Text("• Cashmir Wood: 부드럽고 고급스러운 나무 향")
                                Text("• Delicate Musky Sensual Woods: 고급스러운 머스크 우드 향, 은은하고 깊음")
                                Text("• Gardenia: 크림 같고 화사한 하얀 꽃 향기")
                                Text("• Green Teas: 녹차 특유의 맑고 차분한 향기")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button(action: {
                            showScentGuide = false
                        }) {
                            Text("닫기")
                                .bold()
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func submitRatings() async {
        isLoading = true
        error = nil
        // 로그인/인증 없이 동작하도록, 실제 저장 로직은 생략
        // 필요하다면 아래에 샘플 데이터 저장 로직 추가 가능
        navigateToFinal = true
        isLoading = false
    }
}

