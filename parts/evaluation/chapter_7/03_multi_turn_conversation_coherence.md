# 7.3 Multi-Turn Conversation Coherence

## Introduction

While task completion metrics (Chapter 7.1) measure whether agents achieve goals and tool accuracy metrics (Chapter 7.2) assess action correctness, multi-turn conversation coherence evaluates the quality of sustained interaction over multiple exchanges. As AI agents move beyond single-query responses to extended dialogues spanning dozens of turns, maintaining coherent, contextually-aware conversations becomes essential for user experience and practical utility.

Multi-turn coherence presents unique challenges absent from single-turn evaluation. Agents must maintain consistent persona and knowledge across exchanges, reference earlier conversation points appropriately, track evolving user needs, and produce responses that build logically on previous turns. A conversation might technically complete its task yet feel disjointed, repetitive, or confusing—degrading user satisfaction and trust even when functional requirements are met.

This document explores the landscape of multi-turn conversation evaluation, from fundamental coherence scoring to sophisticated dialogue flow analysis. Understanding these metrics enables teams to build agents that don't just answer questions correctly but engage users in natural, productive conversations that feel human-guided rather than mechanically generated.

## The Challenge of Multi-Turn Evaluation

### Beyond Single-Turn Metrics

Traditional language model evaluation focuses on isolated input-output pairs:
- BLEU and ROUGE for text similarity
- Perplexity for language modeling quality
- F1 scores for information extraction
- Accuracy for classification tasks

These metrics break down in multi-turn contexts because they ignore:

**Temporal Dependencies**: Each turn builds on previous context. Evaluating turn N without considering turns 1 through N-1 misses the essence of conversation.

**State Management**: Agents maintain internal state (memory, plans, facts) that influences future responses. A coherent conversation requires consistent state evolution.

**Reference Resolution**: Pronouns, deixis, and implicit references only make sense given conversation history:
```
Turn 1: "I'm planning a trip to Paris in June."
Turn 2: "What's the weather like there then?"
        ↑                           ↑    ↑
     (where?)                  (Paris) (June)
```

Evaluating turn 2 in isolation is impossible without turn 1 context.

**Goal Evolution**: User objectives shift during conversation. An agent must recognize when the conversation pivots:
```
Turn 1: "Book me a flight to Boston."
Turn 2: "Actually, I should check hotel prices first."
Turn 3: "Never mind, let's do New York instead."
```

Coherent agents adapt to goal changes rather than rigidly pursuing initial requests.

### Non-Determinism in Conversation

Multi-turn interactions amplify the inherent non-determinism of LLM-based agents:

**Compounding Variability**: Each turn's output influences subsequent turns. Small variations early in a conversation can lead to dramatically different trajectories:
```
Trajectory A: Weather query → Location ambiguity → Clarification → Successful response
Trajectory B: Weather query → Assumed location → Wrong result → Correction cycle → Successful response
```

Both trajectories succeed but differ in efficiency, user experience, and number of turns.

**Multiple Valid Paths**: Unlike task completion where "correct" is often clear, conversation quality is subjective. Multiple conversation styles might all be "coherent":
- Concise and direct vs. verbose and explanatory
- Proactive suggestions vs. reactive responses
- Formal tone vs. casual tone

Evaluation must handle this inherent ambiguity without artificially constraining agent behavior.

**Context Window Limitations**: As conversations extend, older context may fall outside model attention windows or be compressed in memory systems. Coherence evaluation must assess whether agents gracefully handle context limitations rather than suddenly "forgetting" earlier discussion.

## Coherence Scoring Methodologies

### LLM-as-Judge for Coherence

Weights & Biases Weave introduces LLM-based coherence scoring that evaluates conversation quality through structured prompts:

**Coherence Evaluation Template**:
```
Evaluate the coherence of this multi-turn conversation.

Conversation History:
{turn_1}
{turn_2}
...
{turn_n}

Rate coherence on a 1-5 scale considering:
- Logical flow: Do responses follow naturally from previous turns?
- Consistency: Does the agent maintain consistent knowledge and persona?
- Clarity: Are responses clear and well-structured?
- Contextual awareness: Does the agent appropriately reference earlier turns?
- Completeness: Does each response fully address the user's current need?

Score: [1-5]
Reasoning: [detailed explanation]
```

This approach captures nuanced quality dimensions difficult to encode in deterministic metrics. The LLM judge can recognize:
- Subtle inconsistencies in agent reasoning
- Inappropriate tone shifts
- Missing acknowledgments of user corrections
- Failure to build on established context

**Multi-Dimensional Scoring**: Rather than a single coherence score, W&B Weave evaluates orthogonal dimensions:

1. **Clarity**: Are individual responses well-articulated and understandable?
2. **Correctness**: Are factual claims and information accurate?
3. **Logical Soundness**: Do agent responses follow valid reasoning?
4. **Contextual Appropriateness**: Does the agent demonstrate conversation awareness?

Separating dimensions enables targeted debugging. An agent might score highly on clarity and correctness but poorly on contextual appropriateness, indicating issues with memory or context injection rather than core language capabilities.

### Conversation-Level vs. Turn-Level Coherence

Coherence can be evaluated at two distinct granularities:

**Turn-Level Coherence**: Evaluating each individual agent response given conversation history:
```
For turn i:
  Coherence_i = f(turn_i, history_{1:i-1})
```

Turn-level metrics enable fine-grained identification of specific problematic responses. They answer: "Which turn broke coherence?"

**Conversation-Level Coherence**: Evaluating the entire dialogue as a holistic unit:
```
Conversation_Coherence = g(turn_1, turn_2, ..., turn_n)
```

Conversation-level metrics capture emergent properties:
- Overall narrative arc and flow
- Progression toward user goals
- Accumulation of context over many turns
- Recovery from early mistakes

Production systems typically track both: turn-level metrics for debugging and conversation-level metrics for user experience optimization.

### Context-Aware Assessment

DeepEval's multi-turn conversation evaluation emphasizes context-aware assessment—evaluating whether agents appropriately use conversation history:

**Context Utilization Metrics**:

1. **Reference Accuracy**: When the agent references earlier conversation, are those references correct?
```
Turn 3: "As you mentioned earlier, you prefer morning flights."
         ↑
     Was this actually mentioned? If so, which turn?
```

2. **Memory Consistency**: Does the agent remember user-stated preferences, facts, and constraints?
```
Turn 2: "I'm vegetarian."
Turn 7: "Here's a steakhouse recommendation."  ← Inconsistent!
```

3. **Implicit Context Handling**: Does the agent correctly resolve references without explicit mentions?
```
Turn 5: "What about the red one?"
        ↑
    Correctly identifying "the red one" from earlier product discussion
```

4. **Context Windowing**: As conversations grow, does the agent gracefully handle context limits?
```
Turn 50: Appropriate behavior might include:
  - Summarizing earlier discussion
  - Asking clarifying questions about older context
  - Acknowledging limitations: "Earlier in our conversation..."
```

Context-aware assessment moves beyond surface coherence (responses read fluently) to functional coherence (responses demonstrate genuine understanding of conversation state).

## Dialogue Flow and Structure Analysis

### Turn Transition Quality

The connection between consecutive turns reveals conversation quality:

**Smooth Transitions**:
- Agent response directly addresses user query
- Natural acknowledgment of user input
- Appropriate continuation of conversation thread

**Jarring Transitions**:
- Non-sequitur responses
- Ignoring user corrections or redirections
- Abrupt topic changes without acknowledgment

**Transition Evaluation Framework**:
```python
def evaluate_transition(turn_i, turn_i_minus_1, context):
    """
    Scores:
    5: Perfectly natural transition
    4: Smooth with minor awkwardness
    3: Functional but noticeably mechanical
    2: Somewhat disjointed
    1: Complete non-sequitur
    """
    factors = {
        'relevance': check_topical_relevance(turn_i, turn_i_minus_1),
        'acknowledgment': check_user_input_acknowledged(turn_i, turn_i_minus_1),
        'progression': check_conversation_advances(turn_i, context),
        'naturalness': check_linguistic_naturalness(turn_i)
    }
    return weighted_score(factors)
```

### Conversational Repair and Recovery

Humans naturally repair conversation breakdowns through clarification, correction, and acknowledgment. Coherent agents must exhibit similar capabilities:

**Repair Patterns**:

1. **Clarification Requests**:
```
User: "Book a table."
Agent: "I'd be happy to help! Could you specify which restaurant and what time?"
```

Rather than guessing or failing, the agent requests missing information.

2. **Error Acknowledgment**:
```
User: "Actually, I meant next Friday, not this Friday."
Agent: "Thank you for clarifying. I'll change the reservation to next Friday, June 14th."
```

The agent explicitly acknowledges the correction and confirms the update.

3. **Assumption Validation**:
```
Agent: "I'll book the 7 PM slot. Does that work for you?"
```

Rather than silently making decisions, the agent surfaces assumptions for validation.

**Repair Evaluation Metrics**:
- **Clarification rate**: Frequency of appropriate clarification requests
- **Correction handling**: Success rate in processing user corrections
- **Confirmation patterns**: Frequency of confirming critical decisions
- **Error recovery time**: Number of turns to recover from misunderstandings

Agents that never request clarification might seem efficient but risk making incorrect assumptions. Conversely, agents that over-clarify create frustrating user experiences. Balancing confidence and caution represents a key coherence challenge.

### Topic Coherence and Segmentation

Multi-turn conversations often span multiple topics or sub-tasks:

```
Conversation segments:
[Turns 1-5: Flight booking]
[Turns 6-12: Hotel search]
[Turns 13-15: Restaurant recommendations]
[Turns 16-20: Return to flight modification]
```

**Topic Coherence Metrics**:

1. **Segment Consistency**: Within a topic segment, does the agent maintain focus?
2. **Transition Smoothness**: When topics shift, does the agent acknowledge the transition?
3. **Topic Tracking**: Can the agent return to earlier topics with appropriate context?

**Topic Segmentation Evaluation**:
```python
def evaluate_topic_coherence(conversation):
    segments = identify_topic_segments(conversation)
    
    metrics = {}
    for segment in segments:
        metrics[segment.id] = {
            'internal_coherence': score_segment_consistency(segment),
            'entry_transition': score_transition(segment.first_turn),
            'exit_transition': score_transition(segment.last_turn),
            'focus_maintenance': score_topic_drift(segment)
        }
    
    return aggregate_segment_metrics(metrics)
```

Poor topic coherence manifests as:
- Drifting within segments (discussing flights, suddenly mentioning hotels unprompted)
- Awkward transitions (jumping topics without acknowledgment)
- Losing earlier context when returning to previous topics

### Conversation Closure

Coherent conversations require appropriate endings:

**Proper Closure Patterns**:
1. **Task completion acknowledgment**: "Your flight is booked. Is there anything else?"
2. **Summary provision**: "To recap: I've booked your flight and hotel."
3. **Open-ended follow-up**: "Let me know if you need any other assistance."
4. **Graceful exit**: Acknowledging conversation end rather than abrupt termination

**Premature Closure Problems**:
- Ending conversation before task completion
- Failing to confirm user satisfaction
- No opportunity for follow-up questions

**Extended Closure Problems**:
- Continuing conversation after user signals completion
- Repetitive closing statements
- Inability to recognize conversation end

Closure evaluation assesses whether agents appropriately recognize when tasks are complete and conversations should conclude.

## Persona and Tone Consistency

### Maintaining Consistent Voice

Agents often have defined personas or communication styles. Coherence requires maintaining these across conversations:

**Persona Elements**:
- **Formality level**: Professional vs. casual language
- **Verbosity**: Concise vs. detailed responses
- **Enthusiasm**: Neutral vs. expressive tone
- **Domain expertise**: Technical vs. accessible explanations

**Persona Drift Detection**:
```python
def evaluate_persona_consistency(conversation, target_persona):
    """
    Target persona: {formality: 'professional', verbosity: 'moderate'}
    """
    per_turn_scores = []
    for turn in conversation.agent_turns:
        formality_score = measure_formality(turn.text)
        verbosity_score = measure_verbosity(turn.text)
        
        deviation = compute_deviation(
            actual={'formality': formality_score, 'verbosity': verbosity_score},
            target=target_persona
        )
        per_turn_scores.append(deviation)
    
    consistency_score = 1 - variance(per_turn_scores)
    return consistency_score
```

**Common Persona Inconsistencies**:
- Switching from formal to casual mid-conversation
- Varying detail levels without user prompting
- Tone shifts (friendly → curt, helpful → dismissive)
- Inconsistent domain knowledge demonstration

Production agents with well-defined personas should maintain consistency scores above 0.9, indicating minimal drift.

### Emotional Appropriateness

Beyond mechanical consistency, coherent agents demonstrate appropriate emotional awareness:

**Empathy Expression**:
```
User: "I need to cancel my trip. My father passed away."
Appropriate: "I'm so sorry for your loss. I'll help you cancel right away."
Inappropriate: "Understood. Canceling reservation. Anything else?"
```

**Frustration Handling**:
```
User: "This is the third time I'm telling you! I want a refund!"
Appropriate: "I apologize for the confusion. Let me make sure I understand: you're requesting a refund for..."
Inappropriate: "As I mentioned before, refunds are processed within 5-7 business days."
```

**Celebration/Success**:
```
User: "Perfect! That's exactly what I needed."
Appropriate: "Wonderful! I'm glad I could help. Safe travels!"
Inappropriate: "Confirmed. Transaction complete."
```

Emotional appropriateness evaluation remains challenging for automated systems but significantly impacts user perception of coherence. LLM-as-judge approaches can capture these nuances:

```
Evaluate emotional appropriateness:
User emotional state: {frustrated/neutral/pleased}
Agent response tone: {text}

Is the agent's tone appropriate given the user's emotional state?
- Yes, perfectly matched
- Mostly appropriate with minor issues
- Somewhat inappropriate
- Very inappropriate

Explanation: [reasoning]
```

## Memory and State Management Evaluation

### Short-Term Memory Assessment

Short-term (within-conversation) memory enables agents to track:
- User preferences stated during conversation
- Decisions made in earlier turns
- Facts or constraints mentioned
- Current sub-task or goal

**Memory Accuracy Testing**:
```python
def test_short_term_memory(agent, conversation_history):
    """
    Inject test questions requiring memory recall
    """
    test_cases = [
        {
            'turn': 15,
            'inject': "What time did I say I wanted to leave?",
            'expected_reference': 'turn_3',  # User mentioned "7 AM departure"
            'evaluation': check_memory_recall
        },
        {
            'turn': 20,
            'inject': "Did I pick the window or aisle seat?",
            'expected_reference': 'turn_12',
            'evaluation': check_memory_recall
        }
    ]
    
    results = []
    for test in test_cases:
        response = agent.process_turn(test['inject'], conversation_history[:test['turn']])
        results.append(test['evaluation'](response, test['expected_reference']))
    
    return aggregate_results(results)
```

**Memory Failure Modes**:
1. **Forgetting**: Not recalling information that was stated
2. **Confabulation**: "Remembering" things that weren't stated
3. **Misattribution**: Correctly recalling information but attributing it to wrong source
4. **Temporal confusion**: Mixing up when information was provided

### Long-Term Memory Evaluation

Some agents maintain long-term memory across sessions:
- User profile information
- Historical preferences
- Previous conversations
- Learned patterns

**Cross-Session Coherence**:
```
Session 1 (Monday):
  User: "I prefer aisle seats."
  Agent: "Noted. I've updated your preferences."

Session 2 (Thursday):
  Agent: "Based on your preference, I've selected an aisle seat."
  ↑
  Correctly using cross-session memory
```

**Long-Term Memory Evaluation**:
- **Persistence accuracy**: Is stored information correct?
- **Retrieval appropriateness**: Is memory accessed when relevant?
- **Update consistency**: Are preferences updated based on new information?
- **Privacy compliance**: Is sensitive information handled appropriately?

Long-term memory adds complexity to coherence evaluation, as assessments must consider information from outside the current conversation.

### State Consistency Testing

Agent internal state should evolve consistently throughout conversation:

**State Variables**:
- Current task/goal
- Active constraints and preferences
- Completed sub-tasks
- Pending actions

**State Transition Validation**:
```python
def validate_state_consistency(conversation_trace):
    """
    conversation_trace includes internal state snapshots after each turn
    """
    violations = []
    
    for i in range(1, len(conversation_trace)):
        prev_state = conversation_trace[i-1].state
        curr_state = conversation_trace[i].state
        user_input = conversation_trace[i].user_turn
        
        # Check if state transition is justified by user input
        if not valid_transition(prev_state, curr_state, user_input):
            violations.append({
                'turn': i,
                'prev': prev_state,
                'curr': curr_state,
                'justification': user_input,
                'issue': diagnose_transition_problem(prev_state, curr_state, user_input)
            })
    
    return violations
```

State inconsistencies cause incoherent behavior:
- Forgetting completed sub-tasks
- Reverting to earlier states without reason
- Contradicting established constraints
- Losing track of the current goal

## Benchmark Datasets and Standardized Evaluation

### Multi-Turn Benchmark Construction

Effective multi-turn evaluation requires carefully constructed datasets:

**Essential Characteristics**:

1. **Conversational Diversity**:
   - Simple request-response patterns (2-3 turns)
   - Complex negotiations (5-10 turns)
   - Extended interactions with topic shifts (15+ turns)
   - Error recovery scenarios

2. **Coherence Challenges**:
   - Pronoun and reference resolution
   - User corrections mid-conversation
   - Ambiguous requests requiring clarification
   - Topic shifts and resumptions
   - Context that exceeds typical attention windows

3. **Ground Truth Annotations**:
   - Expected agent behaviors at key turns
   - Acceptable response variations
   - Critical information that must be remembered
   - Points where clarification is appropriate

**Example Multi-Turn Test Case**:
```json
{
  "conversation_id": "travel_booking_001",
  "turns": [
    {
      "turn_num": 1,
      "user": "I need to book a flight to Paris.",
      "evaluation_criteria": {
        "should_clarify": ["dates", "departure_city"],
        "should_not_assume": ["specific_dates", "airline_preference"]
      }
    },
    {
      "turn_num": 2,
      "user": "Next month, flexible on dates.",
      "evaluation_criteria": {
        "should_remember": ["destination: Paris", "timeframe: next month"],
        "should_clarify": ["departure_city", "date_range_within_month"]
      }
    },
    {
      "turn_num": 3,
      "user": "Actually, make it London instead.",
      "evaluation_criteria": {
        "should_acknowledge_change": true,
        "should_update_memory": {"destination": "Paris → London"},
        "should_maintain_memory": {"timeframe": "next month"}
      }
    }
  ]
}
```

### Automated Coherence Evaluation Pipelines

W&B Weave and similar platforms enable continuous multi-turn evaluation:

**Evaluation Pipeline Architecture**:
```
1. Test Case Selection
   ↓
2. Agent Execution (capturing full conversation)
   ↓
3. Multi-Dimensional Scoring
   - Turn-level coherence
   - Conversation-level coherence
   - Memory consistency
   - Topic coherence
   ↓
4. Aggregation and Reporting
   ↓
5. Failure Analysis (identifying problematic patterns)
   ↓
6. Regression Testing (ensuring improvements don't break existing capabilities)
```

**Continuous Evaluation Benefits**:
- Early detection of coherence regressions
- Comparative analysis across agent versions
- Identification of systematic failure patterns
- Performance tracking over time

Production teams typically establish coherence thresholds:
```
Deployment Gates:
- Average conversation coherence ≥ 4.0/5.0
- No more than 5% of conversations below 3.0/5.0
- Memory consistency ≥ 95%
- Proper closure rate ≥ 90%
```

Failing to meet thresholds blocks deployment, ensuring user experience maintains acceptable quality.

## Practical Implementation Strategies

### Evaluation-Driven Development

Multi-turn coherence evaluation should guide development:

**1. Baseline Establishment**:
   - Evaluate initial agent version on diverse multi-turn dataset
   - Identify primary failure modes (memory, transitions, persona, etc.)
   - Establish current performance metrics

**2. Targeted Improvements**:
   - Focus on highest-impact failure modes
   - Implement fixes (prompt engineering, memory architecture, etc.)
   - Re-evaluate on same dataset

**3. Regression Prevention**:
   - Ensure improvements don't degrade other coherence aspects
   - Add new test cases covering fixed scenarios
   - Monitor metric trends over development cycles

### Human Evaluation Integration

Automated coherence metrics guide development, but human evaluation provides ground truth:

**Human Evaluation Protocol**:
```
Evaluators review complete conversations and rate:
1. Overall coherence (1-5 scale)
2. Specific issues (checklist):
   - Memory failures
   - Poor transitions
   - Persona inconsistencies
   - Inadequate clarifications
   - Inappropriate closures
3. Free-form feedback on most jarring elements
```

**Calibrating Automated Metrics**:
- Compute correlation between automated scores and human judgments
- Identify discrepancies (where automated metrics miss issues)
- Refine automated evaluation to better align with human perception
- Iteratively improve alignment

Target: Spearman correlation ≥ 0.8 between automated coherence scores and human ratings.

### Context Window Optimization

As conversations extend, context management becomes critical:

**Strategies**:

1. **Selective Context Retention**:
   - Summarize older conversation turns
   - Prioritize critical information (user preferences, decisions)
   - Deprioritize routine acknowledgments

2. **Explicit Memory Systems**:
   - Separate long-term memory from conversation context
   - Structured storage (key-value) rather than raw text
   - Selective retrieval based on current turn relevance

3. **Graceful Degradation**:
   - Acknowledge limitations: "Earlier in our conversation..."
   - Offer to review history: "Would you like me to recap?"
   - Request re-statement: "Could you remind me...?"

Coherence evaluation should test agents across various conversation lengths to ensure robust context management.

## Conclusion

Multi-turn conversation coherence represents a critical yet challenging evaluation dimension for AI agents. While task completion (Chapter 7.1) and tool usage (Chapter 7.2) assess functional correctness, coherence evaluates the quality of user interaction—whether conversations feel natural, consistent, and contextually aware.

Effective coherence evaluation combines multiple approaches: LLM-as-judge scoring for nuanced assessment, structured dialogue analysis for systematic evaluation, memory testing for consistency verification, and human evaluation for ground truth calibration. As agents handle increasingly complex, extended interactions, robust coherence evaluation becomes essential for delivering satisfying user experiences.

The techniques explored here—from turn transition analysis to persona consistency tracking—provide a comprehensive framework for assessing and improving multi-turn conversation quality. Looking forward, context retention (Chapter 7.4) and error recovery (Chapter 7.5) build upon these coherence foundations to address even more sophisticated agent capabilities.

## Bibliography

1. DeepEval Documentation. (2025). "Multi-Turn Conversation Evaluation." Retrieved from https://deepeval.com/guides/guides-ai-agent-evaluation

2. Weights & Biases. (2025). "AI Agent Evaluation: Multi-Turn Coherence Metrics and Strategies." Retrieved from https://wandb.ai/onlineinference/genai-research/reports/AI-agent-evaluation-Metrics-strategies-and-best-practices--VmlldzoxMjM0NjQzMQ

3. Microsoft Research. (2024). "Evaluating Dialogue Coherence in Multi-Turn Conversations." Retrieved from https://www.microsoft.com/en-us/research/

4. OpenAI. (2024). "GPT-4 Technical Report: Multi-Turn Dialogue Capabilities." Retrieved from https://openai.com/research/gpt-4

5. Anthropic. (2024). "Claude: Constitutional AI and Conversational Coherence." Retrieved from https://www.anthropic.com/research

6. Google DeepMind. (2024). "Evaluating Long-Context Language Models." Retrieved from https://deepmind.google/research/
