# AI Implementation Specification
**DEFINITIVE GUIDE - DO NOT CREATE ALTERNATIVE SPECS**

---

## 1. MODEL SELECTION

### Primary Model (PROVEN FOR 4GB RAM)
- **Model:** Qwen-SEA-LION-v4-4B-VL
- **Package:** `llama_cpp_dart: ^0.9.x`
- **File:** `Qwen-SEA-LION-v4-4B-VL.Q4_K_M.gguf`
- **File Size:** ~2.5GB
- **RAM Usage:** ~1.8GB peak (measured)
- **Download URL:** https://huggingface.co/mradermacher/Qwen-SEA-LION-v4-4B-VL-GGUF/resolve/main/Qwen-SEA-LION-v4-4B-VL.Q4_K_M.gguf
- **Languages:** Filipino, Indonesian, Thai, Vietnamese, Tagalog

### Fallback Model (TEST BEFORE USE)
- **Model:** Gemma-SEA-LION-v4.5-E2B
- **File:** Gemma-SEA-LION-v4.5-E2B-IT-Q4_K_M.gguf
- **File Size:** ~3.4GB
- **Warning:** May exceed 4GB RAM - requires device testing

### Model Comparison Table
| Model | Params | Q4_K_M Size | RAM | 4GB Compatible |
|-------|--------|-------------|-----|-----------------|
| Qwen 4B VL | 4B | 2.5GB | 1.8GB | ✅ Yes |
| Gemma E2B | 2.7B | 3.4GB | ~3.0GB | ⚠️ Test on device |
| Gemma 9B | 9B | 4.3GB | ~4.0GB+ | ❌ No |

---

## 2. RUNTIME ARCHITECTURE

### Core Dependency
```yaml
dependencies:
  llama_cpp_dart: ^0.9.x
```

### Native Integration REQUIRED
1. Download Android AAR (arm64-v8a) from llama_cpp_dart releases
2. Place in `android/app/libs/`
3. Update `android/app/build.gradle`:
```gradle
repositories { flatDir { dirs 'libs' } }
dependencies { implementation(name: 'llama', ext: 'aar') }
```

### Key Properties
- **NOT** a Flutter plugin - FFI bindings only
- **NOT** Vulkan enabled (CPU-only, optional OpenCL on Snapdragon)
- Streaming response: MANDATORY
- Background isolate: REQUIRED (non-blocking UI)
- Grammar-constrained output: AVAILABLE via GBNF

---

## 3. GENERATION MODES

### Mode 1: Form-Based Generation
```dart
// Direct structured output via GBNF grammar
final prompt = '''
Generate lesson plan JSON for:
- Grade levels: $gradeLevels
- Subject: $subject
- Theme: $theme

Output ONLY valid JSON matching schema:
$llawSchema
''';
```

### Mode 2: Chat Assistant Generation
```dart
// Conversation-based with system prompts
final systemPrompt = '''
You are DepEd LMS Lesson Planner Assistant.
Use Filipino language. Generate ILAW format.
Respond with JSON only when appropriate.
''';
```

---

## 4. ANDROID IMPLEMENTATION REQUIREMENTS

### Permissions (MINIMAL)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<!-- NO external storage permissions - model stored in app-private dir -->
```

### Native AAR Integration Steps
1. Download `llama_android_aar_arm64-v8a.aar`
2. Place in `android/app/libs/`
3. Update `android/app/build.gradle`
4. Test native library loads on device

### Storage Location
```dart
final modelPath = '${context.applicationInfo.dataDir}/models/${modelFileName}';
```

---

## 5. MEMORY MANAGEMENT (4GB RAM DEVICES)

### Configuration Parameters
```dart
LlamaCppParams(
  n_CTX: 4096,        // Reduced from 8192 for RAM savings
  n_THREADS: 4,       // Optimal for Snapdragon CPUs
  n_GPU_LAYERS: 0,    // CPU-only for stability
  f16_KV: true,       // Half-precision KV cache
)
```

### Memory Budget (Qwen 4B)
| Component | Memory |
|-----------|--------|
| Model Weights | 2.5GB |
| KV Cache | 500MB |
| Dart/Flutter | 300MB |
| Android OS | 1.2GB (reserved) |
| **Total** | **~4.5GB** |

### Memory Pressure Handling
```dart
if (await getAvailableRam() < 800MB) {
  throw OutOfMemoryException('Insufficient memory');
}
```

---

## 6. DATA FLOW

```
User Input → GenerationController → LlamaService → Streaming Tokens
       ↓
PlanParser (JSON validation) → Riverpod State → Flutter UI
```

---

## 7. ERROR HANDLING & FALLBACKS

### Triple Fallback Chain
1. **Primary:** Qwen 4B model
2. **Fallback:** Gemma E2B model (if tested OK)
3. **Error:** User-friendly message with retry option

### Specific Exceptions
- `OutOfMemoryException` - Switch to smaller model
- Network timeout - Retry with exponential backoff
- Model corruption - Verify checksum, redownload

---

## 8. VERIFICATION CHECKLIST

Before claiming completion, verify:

- [ ] Model downloads with progress bar and checksum verification
- [ ] Generation produces valid JSON in Form Mode
- [ ] Chat Mode maintains conversation history
- [ ] Response time < 5 seconds (simple queries)
- [ ] Peak RAM usage < 3.5GB on test device
- [ ] No OOM kills during generation
- [ ] Native AAR loads successfully
- [ ] Model stored in app-private directory
- [ ] No external storage permissions required

---

## FOR FUTURE AGENTS

⚠️ **DO NOT:**
- Change runtime package (llama_cpp, llamadart, etc.)
- Propose models >4GB for 4GB devices
- Add external storage dependencies
- Assume Vulkan GPU acceleration works automatically
- Create alternative specifications

✅ **DO:**
- Follow this specification exactly
- Test on actual 4GB Android device
- Document verified performance metrics

---

*This document supersedes any conflicting interpretations in specifications.md*