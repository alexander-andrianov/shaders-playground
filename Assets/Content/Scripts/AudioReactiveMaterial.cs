using UnityEngine;

namespace Content.Scripts
{
    [RequireComponent(typeof(AudioSource))]
    [RequireComponent(typeof(Renderer))]
    public class AudioReactiveMaterial : MonoBehaviour
    {
        public AudioSource audioSource;
        public Material targetMaterial;

        [Header("Beat Detection")]
        [Tooltip("The frequency band (index) to monitor for beats. E.g., 0-10 for bass.")]
        public int frequencyBandMin = 0;
        public int frequencyBandMax = 10;
        [Tooltip("Threshold for detecting a beat in the selected frequency band.")]
        public float beatThreshold = 0.5f;
        [Tooltip("Minimum time between detected beats to avoid rapid flickering.")]
        public float beatCooldown = 0.15f;
        [Tooltip("How quickly the beat input fades out after a beat.")]
        public float beatFadeSpeed = 5f;
        [Tooltip("How quickly the beat input jumps up on a beat.")]
        public float beatAttackSpeed = 20f;

        [Header("Shader Properties")]
        [Tooltip("Name of the float property in the shader that receives the beat input (0-1).")]
        public string beatInputPropertyName = "_BeatInput";

        private const int SPECTRUM_SAMPLES = 1024; 
        private float[] audioSamples;
        private float currentBeatInput = 0f;
        private float lastBeatTime = -100f;
        private int _beatInputPropertyID;

        void Start()
        {
            if (!audioSource)
            {
                audioSource = GetComponent<AudioSource>();
            }
            if (!targetMaterial)
            {
                Renderer renderer = GetComponent<Renderer>();
                if (renderer != null)
                {
                    targetMaterial = renderer.material; 
                }
            }

            if (targetMaterial == null)
            {
                Debug.LogError("AudioReactiveMaterial: Target Material is not set and could not be found on the Renderer.", this);
                enabled = false;
                return;
            }
        
            if (audioSource == null)
            {
                Debug.LogError("AudioReactiveMaterial: AudioSource is not set and could not be found on this GameObject.", this);
                enabled = false;
                return;
            }

            audioSamples = new float[SPECTRUM_SAMPLES];
            _beatInputPropertyID = Shader.PropertyToID(beatInputPropertyName);

            frequencyBandMin = Mathf.Max(0, frequencyBandMin);
            frequencyBandMax = Mathf.Min(SPECTRUM_SAMPLES - 1, frequencyBandMax);
            if (frequencyBandMin >= frequencyBandMax)
            {
                Debug.LogWarning("AudioReactiveMaterial: Min frequency band is greater or equal to Max. Adjust values.", this);

                frequencyBandMin = 0;
                frequencyBandMax = Mathf.Min(10, SPECTRUM_SAMPLES - 1);
            }
        }

        private void Update()
        {
            if (targetMaterial == null || audioSource == null)
            {
                return;
            }

            audioSource.GetSpectrumData(audioSamples, 0, FFTWindow.BlackmanHarris);

            var currentBandMaxAmplitude = 0f;
            for (var i = frequencyBandMin; i <= frequencyBandMax; i++)
            {
                if (audioSamples[i] > currentBandMaxAmplitude)
                {
                    currentBandMaxAmplitude = audioSamples[i];
                }
            }
        
            var beatDetectedThisFrame = false;
            if (currentBandMaxAmplitude > beatThreshold && Time.time >= lastBeatTime + beatCooldown)
            {
                lastBeatTime = Time.time;
                beatDetectedThisFrame = true;
            }

            if (beatDetectedThisFrame)
            {
                currentBeatInput = Mathf.Lerp(currentBeatInput, 1.0f, Time.deltaTime * beatAttackSpeed);
            }
            else
            {
                currentBeatInput = Mathf.Lerp(currentBeatInput, 0.0f, Time.deltaTime * beatFadeSpeed);
            }
        
            currentBeatInput = Mathf.Clamp01(currentBeatInput);
            targetMaterial.SetFloat(_beatInputPropertyID, currentBeatInput);
        }

        void OnDestroy()
        {
            if (targetMaterial == null) return;
            
            var renderer = GetComponent<Renderer>();
            if (renderer != null && renderer.sharedMaterial != targetMaterial)
            {
                Destroy(targetMaterial);
            }
        }
    }
}