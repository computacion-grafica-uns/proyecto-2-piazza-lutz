using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamaraEscenaB : MonoBehaviour
{
    public enum CameraMode { FirstPerson, Orbital }
    public CameraMode currentMode = CameraMode.FirstPerson;

    [Header("General")]
    public Transform orbitalTarget;      // Punto alrededor del cual orbita la cámara
    public float switchCooldown = 0.5f;  // Previene cambio múltiple por frame

    [Header("First Person Settings")]
    public float moveSpeed = 5f;
    public float lookSpeed = 2f;
    private float yaw, pitch;

    [Header("Orbital Settings")]
    public float orbitalDistance = 5f;
    public float orbitalSpeed = 50f;
    private float orbitalYaw = 0f;
    private float orbitalPitch = 20f;

    private float switchTimer = 0f;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;
        yaw = angles.y;
        pitch = angles.x;
        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        switchTimer -= Time.deltaTime;

        // Cambiar entre modos
        if (Input.GetKeyDown(KeyCode.V) && switchTimer <= 0f)
        {
            currentMode = (currentMode == CameraMode.FirstPerson) ? CameraMode.Orbital : CameraMode.FirstPerson;
            switchTimer = switchCooldown;

            Cursor.lockState = (currentMode == CameraMode.FirstPerson)
                ? CursorLockMode.Locked
                : CursorLockMode.None;
        }

        if (currentMode == CameraMode.FirstPerson)
            UpdateFirstPerson();
        else
            UpdateOrbital();
    }

    void UpdateFirstPerson()
    {
        // Mouse look
        float mouseX = Input.GetAxis("Mouse X") * lookSpeed;
        float mouseY = Input.GetAxis("Mouse Y") * lookSpeed;

        yaw += mouseX;
        pitch -= mouseY;
        pitch = Mathf.Clamp(pitch, -89f, 89f);

        transform.eulerAngles = new Vector3(pitch, yaw, 0f);

        // WASD movement
        Vector3 forward = transform.forward;
        Vector3 right = transform.right;
        Vector3 move = Vector3.zero;

        if (Input.GetKey(KeyCode.W)) move += forward;
        if (Input.GetKey(KeyCode.S)) move -= forward;
        if (Input.GetKey(KeyCode.A)) move -= right;
        if (Input.GetKey(KeyCode.D)) move += right;

        transform.position += move.normalized * moveSpeed * Time.deltaTime;
    }

    void UpdateOrbital()
    {
        if (orbitalTarget == null) return;

        // Mouse drag to orbit
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X");
            float mouseY = Input.GetAxis("Mouse Y");

            orbitalYaw += mouseX * orbitalSpeed * Time.deltaTime;
            orbitalPitch -= mouseY * orbitalSpeed * Time.deltaTime;
            orbitalPitch = Mathf.Clamp(orbitalPitch, -85f, 85f);
        }

        // Scroll to zoom
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        orbitalDistance -= scroll * 5f;
        orbitalDistance = Mathf.Clamp(orbitalDistance, 2f, 20f);

        // Calcular posición orbital
        Quaternion rotation = Quaternion.Euler(orbitalPitch, orbitalYaw, 0f);
        Vector3 direction = rotation * Vector3.forward;
        transform.position = orbitalTarget.position - direction * orbitalDistance;
        transform.LookAt(orbitalTarget.position);
    }
}
