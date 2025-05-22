using UnityEngine;

public class AudioReactiveMaterial : MonoBehaviour
{
    public Material targetMaterial;
    public AudioSource audioSource;
    public float beatThreshold = 0.5f;
    public float beatCooldown = 0.5f;
    public float beatFadeSpeed = 5f;
    public int frequencyBandMin = 0;
    public int frequencyBandMax = 255;

    private float[] audioSamples = new float[256];
    private float currentBeatInput = 0f;
    private float lastBeatTime = 0f;
    private int _beatInputPropertyID;

    void Start()
    {
        _beatInputPropertyID = Shader.PropertyToID("_BeatInput");
    }

    void Update()
    {
        if (targetMaterial == null || audioSource == null)
        {
            return;
        }

        audioSource.GetSpectrumData(audioSamples, 0, FFTWindow.BlackmanHarris);

        float currentBandMaxAmplitude = 0f;
        for (int i = frequencyBandMin; i <= frequencyBandMax; i++)
        {
            if (audioSamples[i] > currentBandMaxAmplitude)
            {
                currentBandMaxAmplitude = audioSamples[i];
            }
        }
        
        // --- ОТЛАДОЧНЫЙ ВЫВОД (раскомментируйте для проверки значений) ---
        // Debug.Log("Max Amp in Band: " + currentBandMaxAmplitude + " | Beat Threshold: " + beatThreshold + " | Time: " + Time.time);

        bool beatDetectedThisFrame = false;
        if (currentBandMaxAmplitude > beatThreshold && Time.time >= lastBeatTime + beatCooldown)
        {
            lastBeatTime = Time.time;
            beatDetectedThisFrame = true;
        }

        if (beatDetectedThisFrame)
        {
            // При детекции бита резко устанавливаем currentBeatInput в 1.0
            currentBeatInput = 1.0f; 
        }
        else
        {
            // Затухание: плавно двигаемся к 0.0
            currentBeatInput = Mathf.Lerp(currentBeatInput, 0.0f, Time.deltaTime * beatFadeSpeed);
        }
        
        currentBeatInput = Mathf.Clamp01(currentBeatInput); // Убедимся, что значение всегда между 0 и 1
        targetMaterial.SetFloat(_beatInputPropertyID, currentBeatInput);

        // --- ОТЛАДОЧНЫЙ ВЫВОД (раскомментируйте для проверки значений) ---
        // if (beatDetectedThisFrame || currentBeatInput > 0.01f) // Логировать, если есть бит или затухание еще идет
        // {
        //     Debug.Log("Applied Beat Input to Shader: " + currentBeatInput + " | Beat Detected: " + beatDetectedThisFrame);
        // }
    }
} 