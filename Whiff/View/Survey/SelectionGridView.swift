import SwiftUI

struct SelectionGridView: View {
    let options: [Option]
    @Binding var selectedOption: String?
    let title: String
    let onNext: () -> Void
    var onBack: (() -> Void)? = nil

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            // 질문 텍스트 - 상단 고정
            VStack {
                Text(title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.top, 30)
                    .padding(.horizontal)
                    .padding(.bottom, 24) // ✅ 질문과 선택지 간격 확보
            }

            // 선택지 그리드
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(options) { option in
                    Button(action: {
                        selectedOption = option.name
                    }) {
                        ZStack {
                            Image(option.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipped()
                                .cornerRadius(12)

                            Text(option.name)
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedOption == option.name ? Color.blue : Color.clear, lineWidth: 3)
                        )
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // 버튼 영역
            HStack(spacing: 16) {
                if let onBack = onBack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("이전")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    }
                }

                Button(action: {
                    if selectedOption != nil {
                        onNext()
                    }
                }) {
                    Text("다음")
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedOption != nil ? Color.accentColor : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
                .disabled(selectedOption == nil)
            }
            .padding()
        }
    }
}
