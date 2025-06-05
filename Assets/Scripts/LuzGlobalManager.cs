using UnityEngine;
using System.Collections.Generic;

public class LuzGlobalManager : MonoBehaviour
{
    // --- Punctual Light Properties ---
    [Header("Punctual Light")]
    public Color _PunctualLightIntensity = Color.black;
    public Vector3 _PunctualLightPosition = Vector3.zero;
    private Color _puntualIntensityStored;
    private bool _punctualOn = true;

    // --- Directional Light Properties ---
    [Header("Directional Light")]
    public Color _DirectionalLightIntensity = Color.black;
    public Vector3 _DirectionalLightDirection = Vector3.zero;
    private Color _directionalIntensityStored;
    private bool _directionalOn = true;

    // --- Spot Light Properties ---
    [Header("Spot Light")]
    public Color _SpotLightIntensity = Color.black;
    public Vector3 _SpotLightPosition = Vector3.zero;
    public Vector3 _SpotLightDirection = Vector3.zero;
    [Range(0, 1)]
    public float _SpotLightCircleRadius = 0.25f;
    private Color _spotIntensityStored;
    private bool _spotOn = true;

    [Header("Cámara orbital (asignar manualmente)")]
    public Transform orbitalCameraTransform;
    public Vector3 camaraPosition;
    public Color _AmbientLight = Color.black;

    // List to hold all materials that need light synchronization
    public List<Material> materialsToSync = new List<Material>();

    void Update()
    {
        if (orbitalCameraTransform != null)
        {
            camaraPosition = orbitalCameraTransform.position;

            foreach (Material mat in materialsToSync)
            {
                if (mat != null && mat.HasProperty("_CamaraPosition"))
                {
                    mat.SetVector("_CamaraPosition", camaraPosition);
                }
            }
        }
        if (Input.GetKeyDown(KeyCode.S))
        {
            if (_spotOn)
            {
                _spotIntensityStored = _SpotLightIntensity;
                _SpotLightIntensity = Color.black;
            }
            else
            {
                _SpotLightIntensity = _spotIntensityStored;
            }
            _spotOn = !_spotOn;
            UpdateAllMaterials();
        }
        if (Input.GetKeyDown(KeyCode.D))
        {
            if (_directionalOn)
            {
                _directionalIntensityStored = _DirectionalLightIntensity;
                _DirectionalLightIntensity = Color.black;
            }
            else
            {
                _DirectionalLightIntensity = _directionalIntensityStored;
            }
            _directionalOn = !_directionalOn;
            UpdateAllMaterials();
        }
        if (Input.GetKeyDown(KeyCode.P))
        {
            if (_punctualOn)
            {
                _puntualIntensityStored = _PunctualLightIntensity;
                _PunctualLightIntensity = Color.black;
            }
            else
            {
                _PunctualLightIntensity = _puntualIntensityStored;
            }
            _punctualOn = !_punctualOn;
            UpdateAllMaterials();
        }
    }

    private void OnEnable()
    {
        // Call UpdateAllMaterials whenever the script is enabled or properties are changed in editor
        UpdateAllMaterials();
    }

    // This method will be called when values are changed in the Inspector
    private void OnValidate()
    {
        UpdateAllMaterials();
    }

    // This method updates the shader properties for all synced materials
    public void UpdateAllMaterials()
    {
        camaraPosition = orbitalCameraTransform != null ? orbitalCameraTransform.position : Vector3.zero;

        foreach (Material mat in materialsToSync)
        {
            if (mat == null) continue;

            // Update Punctual Light
            if (mat.HasProperty("_PuntualLightIntensity"))
                mat.SetColor("_PuntualLightIntensity", _PunctualLightIntensity);
            if (mat.HasProperty("_PuntualLightPosition_w"))
                mat.SetVector("_PuntualLightPosition_w", _PunctualLightPosition);

            // Update Directional Light
            if (mat.HasProperty("_DirectionalLightIntensity"))
                mat.SetColor("_DirectionalLightIntensity", _DirectionalLightIntensity);
            if (mat.HasProperty("_DirectionalLightDirection_w"))
                mat.SetVector("_DirectionalLightDirection_w", _DirectionalLightDirection);

            // Update Spot Light
            if (mat.HasProperty("_SpotLightIntensity"))
                mat.SetColor("_SpotLightIntensity", _SpotLightIntensity);
            if (mat.HasProperty("_SpotLightPosition_w"))
                mat.SetVector("_SpotLightPosition_w", _SpotLightPosition);
            if (mat.HasProperty("_SpotLightDirection_w"))
                mat.SetVector("_SpotLightDirection_w", _SpotLightDirection);
            if (mat.HasProperty("_CircleRadius"))
                mat.SetFloat("_CircleRadius", _SpotLightCircleRadius);

            if (mat.HasProperty("_CamaraPosition"))
                mat.SetVector("_CamaraPosition", camaraPosition);
            if (mat.HasProperty("_AmbientLight"))
                mat.SetVector("_AmbientLight", _AmbientLight);
        }
    }
}
