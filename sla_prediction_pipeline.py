import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, roc_auc_score, confusion_matrix
from sklearn.dummy import DummyClassifier # Import DummyClassifier
import xgboost as xgb
import warnings

# --- DATA GENERATION SCRIPT (Part 1) ---

def generate_it_incidents(n_incidents=1000):
    # (Data generation code remains the same)
    incidents = []
    incident_types = ['Network Outage', 'Server Down', 'Application Error', 'Database Issue',
                      'Security Alert', 'Hardware Failure', 'User Access Issue', 'Performance Degradation']
    priorities = ['Low', 'Medium', 'High', 'Critical']
    systems = ['ERP System', 'Email Server', 'CRM', 'Database Server', 'Web Portal',
               'File Server', 'VPN', 'Backup System', 'Monitoring System']
    event_types = ['Reported', 'Acknowledged', 'Investigating', 'Workaround Applied',
                   'Fix Applied', 'Testing', 'Resolved', 'Closed', 'Escalated', 'Reopened']
    start_date = datetime(2024, 1, 1)
    for incident_id in range(1, n_incidents + 1):
        incident_type = random.choice(incident_types)
        priority = random.choice(priorities)
        affected_system = random.choice(systems)
        incident_start = start_date + timedelta(days=random.randint(0, 180), hours=random.randint(0, 23), minutes=random.randint(0, 59))
        
        breach_chance = {'Critical': 0.4, 'High': 0.3, 'Medium': 0.2, 'Low': 0.1}
        will_breach = random.random() < breach_chance[priority]
        
        sla_limits_mins = {'Critical': 240, 'High': 480, 'Medium': 1440, 'Low': 2880}
        sla_limit = sla_limits_mins[priority]
        
        if will_breach:
            resolution_time_mins = random.uniform(sla_limit * 1.1, sla_limit * 2)
        else:
            resolution_time_mins = random.uniform(sla_limit * 0.2, sla_limit * 0.9)
            
        incident_end = incident_start + timedelta(minutes=resolution_time_mins)
        
        num_events = random.randint(3, 10)
        events_for_incident = []
        
        for event_idx in range(num_events):
            event_time_fraction = (event_idx + 1) / num_events
            current_time = incident_start + timedelta(minutes=resolution_time_mins * event_time_fraction * random.uniform(0.8, 1.2))

            if event_idx == 0: event_type = 'Reported'
            elif event_idx == 1: event_type = 'Acknowledged'
            elif event_idx == num_events - 1: event_type = 'Resolved'
            else: event_type = random.choice([t for t in event_types if t not in ['Reported', 'Resolved', 'Closed']])

            event_details = {
                'incident_id': f'INC{incident_id:06d}', 'event_sequence': event_idx + 1,
                'timestamp': current_time, 'event_type': event_type, 'incident_type': incident_type,
                'priority': priority, 'affected_system': affected_system,
                'total_resolution_time_mins': resolution_time_mins, 'sla_breached': will_breach
            }
            if event_type == 'Reported':
                event_details['user_impact_count'] = random.randint(1, 500)
                event_details['severity_score'] = random.randint(1, 10)
            events_for_incident.append(event_details)
        incidents.extend(events_for_incident)
    return pd.DataFrame(incidents)

# Generate and save the dataset
print("Generating IT Incident Dataset...")
df_generated = generate_it_incidents(1000)
df_generated.to_csv('it_incidents_dataset_clean.csv', index=False)
print("\nDataset saved as 'it_incidents_dataset_clean.csv'")
df_generated.to_excel('it_incidents_dataset_clean.xlsx', index=False)
print("Dataset also saved as 'it_incidents_dataset_clean.xlsx'")


# --- ANALYSIS AND MODELING SCRIPT (Part 2) ---
warnings.filterwarnings('ignore')

print("\n🚀 IT Incident SLA Breach Prediction Analysis")
print("=" * 60)

# ==============================================================================
# STEP 1: LOAD AND EXPLORE THE DATA
# ==============================================================================
print("\n📊 STEP 1: DATA EXPLORATION")
print("-" * 30)
df = pd.read_csv('it_incidents_dataset_clean.csv')
df['timestamp'] = pd.to_datetime(df['timestamp'], format='ISO8601')
print(f"Dataset Shape: {df.shape}")
print(f"Unique Incidents: {df['incident_id'].nunique()}")
print(f"Data Quality Assessment: Missing Values={df.isnull().sum().sum()}, Duplicates={df.duplicated().sum()}")

# ==============================================================================
# STEP 2: DEFINE THE PREDICTION PROBLEM
# ==============================================================================
print("\n🎯 STEP 2: PREDICTION PROBLEM DEFINITION")
print("-" * 45)
prediction_target = "sla_breached"
print(f"🎯 PREDICTION TARGET: {prediction_target}")
sla_breach_rate = df.groupby('incident_id')[prediction_target].first().mean()
print(f"Overall SLA Breach Rate: {sla_breach_rate:.1%}")

# ==============================================================================
# STEP 3: DATA PREPROCESSING (FILTER FOR FIRST 3 EVENTS)
# ==============================================================================
print("\n🔧 STEP 3: DATA PREPROCESSING")
print("-" * 35)
df_first3 = df[df['event_sequence'] <= 3].copy()
numeric_cols = df_first3.select_dtypes(include=np.number).columns
df_first3[numeric_cols] = df_first3[numeric_cols].fillna(0)

# ==============================================================================
# STEP 4: FEATURE ENGINEERING
# ==============================================================================
print("\n⚙️ STEP 4: FEATURE ENGINEERING")
print("-" * 35)
def engineer_features(df_filtered):
    feature_list = []
    for incident_id, incident_events in df_filtered.groupby('incident_id'):
        incident_events = incident_events.sort_values('event_sequence')
        first_event = incident_events.iloc[0]
        feature_row = {
            'incident_id': incident_id,
            'incident_type': first_event['incident_type'], 'priority': first_event['priority'],
            'affected_system': first_event['affected_system'], 'initial_user_impact': first_event.get('user_impact_count', 0),
            'initial_severity': first_event.get('severity_score', 0), 'hour_of_day': first_event['timestamp'].hour,
            'day_of_week': first_event['timestamp'].weekday(), 'is_weekend': 1 if first_event['timestamp'].weekday() >= 5 else 0,
            'sla_breached': first_event['sla_breached']
        }
        if len(incident_events) >= 2:
            feature_row['time_to_acknowledge_mins'] = (incident_events.iloc[1]['timestamp'] - first_event['timestamp']).total_seconds() / 60
        else: feature_row['time_to_acknowledge_mins'] = 0
        if len(incident_events) >= 3:
            feature_row['time_between_event2_3_mins'] = (incident_events.iloc[2]['timestamp'] - incident_events.iloc[1]['timestamp']).total_seconds() / 60
        else: feature_row['time_between_event2_3_mins'] = 0
        feature_row['has_escalation_early'] = 1 if 'Escalated' in incident_events['event_type'].tolist() else 0
        feature_list.append(feature_row)
    return pd.DataFrame(feature_list)
feature_df = engineer_features(df_first3)
print(f"Feature matrix shape: {feature_df.shape}")

# ==============================================================================
# STEP 5: MODEL PREPARATION
# ==============================================================================
print("\n📈 STEP 5: MODEL PREPARATION")
print("-" * 30)
X = feature_df.drop(['incident_id', 'sla_breached'], axis=1)
y = feature_df['sla_breached'].astype(int)
categorical_cols = X.select_dtypes(include=['object']).columns
for col in categorical_cols:
    le = LabelEncoder()
    X[col] = le.fit_transform(X[col])
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
print(f"Training set: {X_train.shape}, Test set: {X_test.shape}")

# ==============================================================================
# STEP 6: MODEL BUILDING & EVALUATION
# ==============================================================================
print("\n🤖 STEP 6: MODEL BUILDING & EVALUATION")
print("-" * 42)

# ----- FINAL ADDITION: Baseline Model to meet prompt requirements perfectly -----
print("\nBuilding Baseline Model...")
baseline_model = DummyClassifier(strategy='most_frequent')
baseline_model.fit(X_train, y_train)
baseline_pred_proba = baseline_model.predict_proba(X_test)[:, 1]
print(f"✅ Baseline Model AUC: {roc_auc_score(y_test, baseline_pred_proba):.3f}")


# ----- Advanced Model: XGBoost -----
print("\nBuilding Advanced Model (XGBoost)...")
scale_pos_weight = y_train.value_counts()[0] / y_train.value_counts()[1]
xgb_model = xgb.XGBClassifier(n_estimators=100, random_state=42, max_depth=5, scale_pos_weight=scale_pos_weight, early_stopping_rounds=10)
xgb_model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)
y_pred = xgb_model.predict(X_test)
y_pred_proba = xgb_model.predict_proba(X_test)[:, 1]
print(f"✅ Advanced Model (XGBoost) AUC: {roc_auc_score(y_test, y_pred_proba):.3f}")
print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=['Not Breached', 'Breached']))
print("\nConfusion Matrix:")
cm = confusion_matrix(y_test, y_pred)
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['Not Breached', 'Breached'], yticklabels=['Not Breached', 'Breached'])
plt.xlabel('Predicted')
plt.ylabel('Actual')
plt.title('Confusion Matrix')
plt.show()

# ==============================================================================
# STEP 7: MODEL INTERPRETATION
# ==============================================================================
print("\n🔍 STEP 7: MODEL INTERPRETATION")
print("-" * 35)
feature_importance = pd.DataFrame({'feature': X.columns, 'importance': xgb_model.feature_importances_}).sort_values('importance', ascending=False)
print("🔥 TOP 5 MOST IMPORTANT EARLY WARNING SIGNALS:")
print(feature_importance.head(5).to_string(index=False))

# ==============================================================================
# STEP 8: COUNTERFACTUAL ANALYSIS
# ==============================================================================
print("\n🔄 STEP 8: COUNTERFACTUAL ('WHAT-IF') ANALYSIS")
print("-" * 50)
try:
    non_breach_indices = y_test[y_test == 0].index
    low_priority_non_breach_indices = X_test.loc[non_breach_indices][X_test['priority'] < X['priority'].max()].index
    test_case_index = random.choice(low_priority_non_breach_indices)
    test_case = X_test.loc[[test_case_index]]
    
    original_prob = xgb_model.predict_proba(test_case)[0][1]
    print(f"Original Case: A specific incident had a {original_prob:.1%} predicted risk of SLA breach.")

    modified_case = test_case.copy()
    most_important_feature = feature_importance.iloc[0]['feature']
    original_value = modified_case[most_important_feature].iloc[0]
    
    change_description = ""
    if most_important_feature == 'priority':
        new_value = original_value + 1
        if new_value > X['priority'].max(): new_value = original_value
        change_description = f"upgrading priority from level {int(original_value)} to {int(new_value)}"
        modified_case[most_important_feature] = new_value
    else:
        new_value = original_value * 1.50
        change_description = f"increasing from {original_value:.2f} to {new_value:.2f}"
        modified_case[most_important_feature] = new_value

    modified_prob = xgb_model.predict_proba(modified_case)[0][1]
    print(f"\nWHAT-IF SCENARIO: What if we {change_description}?")
    print(f"Modified Case: The predicted risk changed to {modified_prob:.1%}.")
    print(f"IMPACT: This single change resulted in a {modified_prob - original_prob:+.1%} shift in the predicted risk.")
except (IndexError, KeyError, ValueError):
    print("Could not find a suitable case for counterfactual analysis in the test set.")

print("\n" + "="*60)
print("🏆 Analysis Complete!")