# ✅ 향수 추천 시스템 (emotion_cluster 기반 + 노트 재추천 포함, soft-label 기반 emotion_score + class_weight)

import random, os
import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import f1_score, classification_report
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.utils.class_weight import compute_class_weight
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Input

# ✨ 재현성 설정
random.seed(42)
np.random.seed(42)
os.environ["PYTHONHASHSEED"] = str(42)
tf.random.set_seed(42)

# ✅ Google Drive 연동
from google.colab import drive
drive.mount('/content/drive')
file_path = "/content/drive/MyDrive/(진짜최종_데이터셋)_emotion_cluster_완료.csv"
df = pd.read_csv(file_path)
df['notes'] = df['notes'].fillna('').str.lower()

# ✅ NOTE 정제 함수 정의
def clean_notes(raw_notes):
    notes = [n.strip() for n in raw_notes.split(',')]
    cleaned = [n for n in notes if len(n) > 0 and len(n) < 40]
    return ', '.join(cleaned)

# ✅ NOTE 정제 후 벡터화
df['notes'] = df['notes'].fillna('').apply(clean_notes)
note_vectorizer = CountVectorizer(token_pattern=r'[^,]+')
note_matrix = note_vectorizer.fit_transform(df['notes'])
note_df = pd.DataFrame(note_matrix.toarray(), columns=note_vectorizer.get_feature_names_out())

# ✅ 인코딩 및 학습 준비
encoder = OneHotEncoder(sparse_output=False, handle_unknown='ignore')
X_input = df[['gender', 'season_tags', 'time_tags', 'desired_impression', 'activity', 'weather']]
encoder.fit(X_input.values)
X = encoder.transform(X_input.values)
y = df['emotion_cluster']

# ✅ 데이터 분리
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)

# ✅ 클래스 불균형 보정용 가중치 계산
class_weights = compute_class_weight(class_weight='balanced', classes=np.unique(y_train), y=y_train)
class_weight_dict = {i: w for i, w in zip(np.unique(y_train), class_weights)}

# ✅ 모델 정의 및 학습
model = Sequential([
    Input(shape=(X_train.shape[1],)),
    Dense(128, activation='relu'), Dropout(0.3),
    Dense(128, activation='relu'), Dropout(0.3),
    Dense(6, activation='softmax')
])
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
model.fit(X_train, y_train, epochs=10, validation_data=(X_val, y_val), class_weight=class_weight_dict)

# ✅ 평가 지표 출력
y_pred = model.predict(X_val).argmax(axis=1)
print(classification_report(y_val, y_pred))
print(f"\n📊 F1 Score 결과")
print(f" - Macro F1 Score: {f1_score(y_val, y_pred, average='macro'):.4f}")
print(f" - Weighted F1 Score: {f1_score(y_val, y_pred, average='weighted'):.4f}")

# ✅ 사용자 입력
print("\n👤 사용자 정보를 입력해주세요:")
gender = input("성별 (women/men/unisex): ").strip().lower()
season = input("계절 (spring/summer/fall/winter): ").strip().lower()
time = input("시간대 (day/night): ").strip().lower()
desired_impression = input("주고 싶은 인상 (confident/elegant/pure/friendly/mysterious/fresh): ").strip().lower()
activity = input("활동 (casual/work/date): ").strip().lower()
weather = input("날씨 (hot/cold/rainy/any): ").strip().lower()

user_input = [gender, season, time, desired_impression, activity, weather]
user_vec = encoder.transform([user_input])

# ✅ 감정 soft-label 기반 emotion_score 계산
proba = model.predict(user_vec)[0]
predicted_cluster = np.argmax(proba)
df['emotion_score'] = df['emotion_cluster'].map(lambda c: proba[c])

print("\n🧠 감정 클러스터 예측 결과:")
print(f"예측된 감정 클러스터: {predicted_cluster}")

# ✅ 1차 감정 기반 향수 추천
selected = []
top_sorted = df.sort_values('emotion_score', ascending=False)
for i in top_sorted.index:
    if all(cosine_similarity([note_df.loc[i]], [note_df.loc[j]])[0][0] < 0.95 for j in selected):
        selected.append(i)
    if len(selected) == 10:
        break
top_perfumes = df.loc[selected]
print("\n🌸 1차 감정 기반 추천 향수 Top 10:")
for i, row in top_perfumes.iterrows():
    print(f"{i+1}. {row['name']} / {row['brand']} → 감정 클러스터: {row['emotion_cluster']}")

# ✅ 노트 선호도 입력
note_scores = {}
top_notes_matrix = note_df.loc[top_perfumes.index]
top_notes_sum = top_notes_matrix.sum(axis=0)
top_notes = top_notes_sum.sort_values(ascending=False).head(15).index.tolist()

print("\n📝 1차 추천 향수에 자주 등장하는 노트입니다. 선호도를 입력해주세요 (1~5점):")
for note in top_notes:
    try:
        score = int(input(f"{note}: ").strip())
        note_scores[note] = max(1, min(score, 5))
    except:
        note_scores[note] = 3

# ✅ note_score 계산
user_note_vec = np.zeros((1, len(note_df.columns)))
for i, note in enumerate(note_df.columns):
    score = note_scores.get(note, 0)
    user_note_vec[0, i] = score / 5

note_cos_sim = cosine_similarity(note_df.values, user_note_vec).reshape(-1)
note_sum = np.zeros(len(note_df))
for note, weight in note_scores.items():
    if note in note_df.columns:
        vec = note_df[note]
        if isinstance(vec, pd.DataFrame):
            vec = vec.iloc[:, 0]
        note_sum += vec.to_numpy().ravel() * weight
note_score = 0.7 * note_cos_sim + 0.3 * (note_sum / 10)
df['note_score'] = note_score
df['is_top10'] = df.index.isin(top_perfumes.index).astype(int)

# ✅ final_score 계산 및 재추천
alpha, beta, gamma = 0.7, 0.25, 0.05
df['final_score'] = alpha * df['emotion_score'] + beta * df['note_score'] + gamma * df['is_top10']
df['note_diversity'] = note_df.astype(bool).sum(axis=1)

top10_final = df.sort_values(by=['final_score', 'note_diversity'], ascending=[False, False]).head(10)
print("\n🌟 감정 + 노트 기반 재추천 결과:")
for i, row in top10_final.iterrows():
    explanation = "추천 폭을 넓혀봤어요"
    if row['final_score'] > 0.65:
        explanation = "감정과 노트 모두 매우 잘 맞아요"
    elif row['final_score'] > 0.5:
        explanation = "당신의 취향과 비슷해요"
    print(f"{i+1}. {row['name']} / {row['brand']} → final_score: {row['final_score']:.4f} → {explanation}")
    top_notes = note_df.loc[row.name][note_df.loc[row.name] > 0].index.tolist()[:2]
    for note in top_notes:
        print(f"   - 노트: {note}")
