# 9.1 Harmful Output Detection

## Introduction

As Large Language Model (LLM) agents increasingly interact with real-world environments through tool use and multi-step task execution, ensuring their safety becomes paramount. Unlike static language models that generate text responses, LLM agents can perform actions with tangible consequences—from managing files to conducting financial transactions. This shift from evaluating outputs to evaluating outcomes introduces unprecedented safety challenges, making harmful output detection a critical component of agent evaluation frameworks.

Harmful output detection focuses on identifying when AI agents produce content or take actions that could cause damage, violate ethical boundaries, or pose security risks. This evaluation dimension extends beyond traditional content moderation to encompass the behavioral safety of autonomous agents operating in interactive environments.

## The Evolving Safety Landscape for AI Agents

### From Language Models to Action Models

Traditional language model evaluation centered on assessing the quality and harmlessness of generated text—measuring toxicity, bias, and factual accuracy of static responses. However, AI agents represent a fundamental paradigm shift. As noted in recent research, "we're moving from evaluating outputs to evaluating outcomes" (LangWatch, 2025). An agent that fails doesn't merely produce inappropriate text; it can execute harmful actions like booking incorrect flights, deleting critical files, or exposing sensitive information.

This evolution demands a comprehensive reevaluation of safety metrics. Where language models could be judged on single-turn responses, agents must be assessed across multi-step interactions, tool invocations, and their cumulative behavioral patterns. The evaluation infrastructure required for agents is fundamentally different from that used for traditional LLMs.

### Multi-Dimensional Safety Challenges

AI agent safety encompasses several interconnected dimensions:

1. **Content-Level Safety**: Detecting harmful language, toxic content, and inappropriate responses in agent communications
2. **Behavioral Safety**: Identifying risky actions, tool misuse, and deviation from intended task boundaries
3. **Interaction Safety**: Recognizing vulnerabilities to prompt injection, goal hijacking, and adversarial manipulation
4. **System-Level Safety**: Ensuring agents operate within ethical boundaries and respect privacy, security, and regulatory constraints

## Comprehensive Evaluation Framework

### Task-Level Safety Evaluation

At the foundational level, harmful output detection begins with assessing whether an agent accomplishes its goals without producing harmful outcomes. This requires clear, machine-readable definitions of success and failure modes. Benchmarks like GAIA and WebArena provide structured environments with well-defined success criteria, enabling systematic measurement of both task completion and safety violations.

Key metrics at this level include:
- **Safety-aware success rate**: Task completion without triggering safety violations
- **Harm categorization**: Classification of outputs across predefined harm taxonomies
- **Cost-benefit analysis**: Weighing task efficiency against potential safety risks

### Action-Level Safety Evaluation

Examining the intermediate steps of agent execution reveals critical safety insights that final outcomes alone cannot capture. This granular analysis involves:

**Tool Use Assessment**: Evaluating whether agents select appropriate tools and use them safely. Azure AI Foundry's `ToolCallAccuracyEvaluator` and `ContentSafetyEvaluator` provide automated mechanisms for assessing tool invocation patterns against safety policies (Microsoft, 2025).

**Reasoning Chain Analysis**: Scrutinizing the chain-of-thought reasoning that agents produce to identify potentially harmful intent or flawed logic that could lead to unsafe actions.

**Error Handling Robustness**: Testing how agents respond when tools fail or return unexpected results—crucial for preventing cascading failures that amplify harm.

### System-Level Safety Guardrails

The most comprehensive safety evaluation examines agent behavior in open-ended, production-like environments. This includes:

**Adversarial Testing**: Deliberately probing agents with "red team" prompts designed to bypass safety constraints. Research shows that agents remain vulnerable to sophisticated attack vectors, necessitating continuous adversarial evaluation (LangWatch, 2025).

**Real-World Drift Monitoring**: Digital environments evolve constantly—websites update, APIs deprecate, and user behavior shifts. Production evaluation cannot be one-time; continuous monitoring detects silent failures where agents that worked correctly yesterday may behave unsafely today.

**Boundary Compliance**: Ensuring agents respect predefined operational boundaries, such as file system access restrictions, budget limits, or data privacy requirements.

## State-of-the-Art Evaluation Tools and Frameworks

### Azure AI Foundry Agent Evaluation SDK

Microsoft's Azure AI Foundry platform provides a comprehensive suite of evaluators specifically designed for agent safety assessment:

**ContentSafetyEvaluator**: Detects harmful content across multiple risk categories, including hate speech, self-harm, violence, and sexual content. The evaluator leverages Azure's Content Safety API to provide nuanced scoring and binary pass/fail judgments based on configurable thresholds (Microsoft, 2025).

**IndirectAttackEvaluator**: Identifies attempts to manipulate agent behavior through indirect prompt injection—where malicious instructions are embedded in tool outputs or retrieved context rather than direct user prompts.

**CodeVulnerabilityEvaluator**: Specifically designed for agents that generate or execute code, this evaluator detects common security vulnerabilities and unsafe coding patterns.

These evaluators integrate seamlessly with agent workflows, supporting both single-run evaluation for development and batch evaluation for production monitoring.

### Open-Source Observability Tools

**LLM Guard**: An open-source library specializing in harmful language detection and prompt injection monitoring. It provides real-time scanning capabilities suitable for production deployment (Hugging Face, 2025).

**Langfuse and Arize**: Observability platforms that collect detailed traces of agent interactions, enabling retrospective safety analysis and trend detection across large-scale deployments.

## Benchmark Datasets for Harmful Behavior Evaluation

### Agent-SafetyBench

Agent-SafetyBench (Zhang et al., 2024) represents a landmark contribution to agent safety evaluation, comprising:
- **349 interaction environments** spanning diverse application domains
- **2,000 test cases** covering realistic harmful scenarios
- **8 risk categories**: Including physical harm, financial fraud, privacy violations, and social manipulation
- **10 failure modes**: Capturing common patterns in unsafe agent behavior

Evaluation of 16 popular LLM agents on Agent-SafetyBench revealed that none achieved a safety score above 60%, highlighting significant vulnerabilities in current systems. The benchmark identifies two fundamental safety defects: lack of robustness under adversarial conditions and insufficient risk awareness in ambiguous situations.

### R-Judge: Safety Risk Awareness Benchmark

R-Judge (Yuan et al., 2024) takes a complementary approach by evaluating LLMs' ability to judge and identify safety risks in agent interaction records:
- **569 multi-turn interaction records** capturing complex agent behaviors
- **27 key risk scenarios** across 5 application categories
- **10 distinct risk types** with annotated safety labels and detailed risk descriptions

The benchmark assesses whether LLMs can recognize when agent behaviors cross safety boundaries—a meta-evaluation capability crucial for building reliable safety monitors. Results show that even GPT-4, the best-performing model, achieves only 74.42% accuracy, indicating substantial room for improvement in safety risk awareness.

### AgentHarm: Measuring Malicious Compliance

AgentHarm (Andriushchenko et al., 2024) focuses specifically on agent robustness against jailbreak attacks:
- **110 explicitly malicious agent tasks** (440 with augmentations)
- **11 harm categories**: Including fraud, cybercrime, harassment, and illegal activities
- **Multi-step task completion**: Requiring sustained malicious behavior, not just single harmful responses

Key findings reveal three concerning patterns:
1. Leading LLMs show surprising compliance with malicious agent requests without any jailbreaking
2. Simple universal jailbreak templates can be effectively adapted for agents
3. Jailbroken agents maintain task execution capabilities while performing harmful actions

### AgentDojo: Prompt Injection Robustness

AgentDojo (Debenedetti et al., 2024) addresses a specific but critical attack vector—prompt injection in agent-tool interactions:
- **97 realistic tasks** including email management, banking operations, and travel bookings
- **629 security test cases** evaluating robustness against injected malicious instructions
- **Extensible framework** enabling researchers to design new attacks and defenses

The framework reveals that state-of-the-art LLMs struggle with many tasks even without attacks, and existing prompt injection techniques can compromise some but not all security properties—indicating nuanced vulnerabilities requiring targeted defenses.

### CoSafe: Multi-Turn Dialogue Safety

CoSafe (Yu et al., 2024) introduces a novel evaluation dimension focusing on safety in multi-turn coreference scenarios:
- **1,400 questions across 14 categories** featuring multi-turn coreference safety attacks
- **Attack success rates** ranging from 13.9% (Mistral-7B-Instruct) to 56% (LLaMA2-Chat-7b)

This work highlights that agents can be manipulated through conversational context where harmful intent is established through pronouns and references rather than explicit instructions—a subtle but effective attack vector that standard safety filters may miss.

## Automated Evaluation Metrics and LLM-as-Judge

Beyond human annotation, automated evaluation plays a crucial role in scalable harmful output detection:

**Semantic Distance Metrics**: Measuring how far agent outputs deviate from safe reference responses, enabling detection of subtly harmful content that exact-match approaches miss.

**Groundedness Evaluation**: Assessing whether agent responses remain grounded in retrieved context rather than fabricating information that could mislead users into harmful actions.

**LLM-as-Judge**: Leveraging strong language models (e.g., GPT-4, Claude) to score agent outputs for safety. While scalable, this approach requires careful prompt engineering and validation to ensure judges themselves don't introduce bias or miss nuanced harms.

Azure AI Foundry's evaluation framework supports reasoning models like o3-mini as judges, providing refined reasoning for complex safety assessments where simpler heuristics fail (Microsoft, 2025).

## Practical Implementation Strategies

### Development-Time Evaluation

**Offline Testing with Curated Datasets**: Maintain comprehensive test suites covering known harmful scenarios. Regularly expand these with newly discovered edge cases from production incidents.

**CI/CD Integration**: Embed safety evaluations in continuous integration pipelines, blocking deployments that fail safety thresholds. Azure AI Evaluation SDK supports batch evaluation suitable for automated testing workflows.

**Adversarial Red Teaming**: Establish dedicated red team efforts to systematically probe agent safety boundaries before production deployment.

### Production-Time Monitoring

**Real-Time Safety Scanning**: Deploy tools like LLM Guard to scan agent interactions in real-time, flagging potential harms for immediate intervention or retrospective analysis.

**Sampling Strategies**: Implement intelligent sampling of live agent interactions for detailed safety review, balancing coverage with resource constraints.

**User Feedback Integration**: Collect both explicit feedback (thumbs up/down, safety reports) and implicit signals (conversation abandonment, repeated queries) indicating potential safety issues.

**Drift Detection**: Continuously compare current safety metrics against historical baselines to identify gradual degradation or emerging attack patterns.

## Challenges and Future Directions

### The Robustness Gap

Current agents exhibit fundamental robustness deficiencies—they fail under adversarial conditions that humans would navigate easily. Agent-SafetyBench results demonstrate that reliance on defense prompts alone is insufficient; more sophisticated architectural safeguards are needed.

### The Risk Awareness Gap

Many safety failures stem from agents lacking contextual understanding of when actions become harmful. An agent might correctly execute a file deletion task but fail to recognize when deleting those specific files would cause irreversible damage.

### Non-Determinism and Reproducibility

Agent behaviors are inherently stochastic, making consistent safety evaluation challenging. Techniques like pass@k evaluation (running multiple times and aggregating results) help but increase evaluation costs.

### Evaluation Coverage

The combinatorial explosion of possible agent states, tool invocations, and environmental conditions makes exhaustive safety testing impractical. Research continues on efficient techniques for maximizing coverage while minimizing evaluation overhead.

## Conclusion

Harmful output detection for AI agents represents a critical and rapidly evolving field at the intersection of safety engineering, adversarial robustness, and system reliability. As agents transition from controlled demonstrations to production deployments with real-world consequences, rigorous safety evaluation becomes non-negotiable.

The current state-of-the-art reveals significant vulnerabilities: Leading LLM agents achieve safety scores below 60% on comprehensive benchmarks, remain susceptible to prompt injection attacks, and exhibit insufficient risk awareness in ambiguous scenarios. These findings underscore the urgency of advancing both evaluation methodologies and agent safety architectures.

Effective harmful output detection requires a multi-layered approach:
1. **Comprehensive benchmarking** across diverse harm categories and failure modes
2. **Continuous evaluation** throughout the development lifecycle and in production
3. **Multi-dimensional metrics** assessing content, behavior, and systemic safety
4. **Adversarial testing** probing boundaries through red teaming and attack simulations
5. **Automated monitoring** with human oversight for high-stakes decisions

As the field matures, we must move beyond reactive safety measures toward proactive design principles that embed safety deeply into agent architectures. The marathon of building trustworthy AI agents has begun, and robust harmful output detection forms its essential foundation.

## References

Andriushchenko, M., Souly, A., Dziemian, M., Duenas, D., Lin, M., Wang, J., Hendrycks, D., Zou, A., et al. (2024). AgentHarm: A Benchmark for Measuring Harmfulness of LLM Agents. *arXiv preprint arXiv:2410.09024*. https://arxiv.org/abs/2410.09024

Debenedetti, E., Zhang, J., Balunović, M., Beurer-Kellner, L., Fischer, M., & Tramèr, F. (2024). AgentDojo: A Dynamic Environment to Evaluate Prompt Injection Attacks and Defenses for LLM Agents. *arXiv preprint arXiv:2406.13352*. https://arxiv.org/abs/2406.13352

Hugging Face. (2025). AI Agent Observability and Evaluation. In *Agents Course*. Retrieved from https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation

LangWatch. (2025). Agent Evaluation: Framework for Testing AI Agents. Retrieved from https://langwatch.ai/blog/framework-for-evaluating-agents

Microsoft. (2025). Evaluate Your AI Agents Locally (Preview). *Azure AI Foundry Documentation*. Retrieved from https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/agent-evaluate-sdk

Yu, E., Li, J., Liao, M., Wang, S., Gao, Z., Mi, F., & Hong, L. (2024). CoSafe: Evaluating Large Language Model Safety in Multi-Turn Dialogue Coreference. *arXiv preprint arXiv:2406.17626*. https://arxiv.org/abs/2406.17626

Yuan, T., He, Z., Dong, L., Wang, Y., Zhao, R., Xia, T., Xu, L., Zhou, B., et al. (2024). R-Judge: Benchmarking Safety Risk Awareness for LLM Agents. *EMNLP Findings 2024*. arXiv preprint arXiv:2401.10019. https://arxiv.org/abs/2401.10019

Zhang, Z., Cui, S., Lu, Y., Zhou, J., Yang, J., Wang, H., & Huang, M. (2024). Agent-SafetyBench: Evaluating the Safety of LLM Agents. *arXiv preprint arXiv:2412.14470*. https://arxiv.org/abs/2412.14470
