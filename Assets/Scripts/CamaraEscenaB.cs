using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class CamaraEscenaB : MonoBehaviour
{
    public enum CameraMode { FirstPerson, Orbital }
    public CameraMode currentMode = CameraMode.FirstPerson;

    [Header("General")]
    public float switchCooldown = 0.5f;  // Previene cambio múltiple por frame

    [Header("First Person Settings")]
    public float moveSpeed = 2.5f;
    public float lookSpeed = 2f;
    private float yaw, pitch;
    public Vector3 initialFirstPersonPosition = new Vector3(0f, -400f, 0f);
    public Vector3 initialFirstPersonRotation = new Vector3(0f, 0f, 0f);

    [Header("Orbital Settings")]
    public float distance = 75f;
    public float rotationSpeed = 2000f;
    private float orbitalYaw = 0f;
    private float orbitalPitch = 20f;

    private float switchTimer = 0f;

    public Transform[] targets;
    private int currentTargetIndex = 0;
    private float fixedY;

    void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
        transform.position = initialFirstPersonPosition;
        transform.eulerAngles = initialFirstPersonRotation;
        yaw = initialFirstPersonRotation.y;
        pitch = initialFirstPersonRotation.x;
        fixedY = initialFirstPersonPosition.y;

        targets = GameObject.FindGameObjectsWithTag("FocusTarget")
            .OrderBy(obj => obj.name)
            .Select(obj => obj.transform)
            .ToArray();
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

        Vector3 newPos = transform.position + move.normalized * moveSpeed * Time.deltaTime;
        newPos.y = fixedY;

        transform.position = newPos;
        
    }

    void UpdateOrbital()
    {
        if (targets.Length == 0) return;
        if (Input.GetKeyDown(KeyCode.Tab))
        {
            if (Input.GetKey(KeyCode.LeftShift))
            {
                currentTargetIndex = (currentTargetIndex - 1) % targets.Length;
            }
            else
            {
                currentTargetIndex = (currentTargetIndex + 1) % targets.Length;
            }

            Transform newTarget = targets[currentTargetIndex];
            Vector3 toCamera = (transform.position - newTarget.position).normalized;
            orbitalYaw = Mathf.Atan2(toCamera.x, toCamera.z) * Mathf.Rad2Deg;
            orbitalPitch = Mathf.Asin(toCamera.y) * Mathf.Rad2Deg;
        }

        // Mouse orbita
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X");
            float mouseY = Input.GetAxis("Mouse Y");

            orbitalYaw += mouseX * rotationSpeed * Time.deltaTime;
            orbitalPitch -= mouseY * rotationSpeed * Time.deltaTime;
            orbitalPitch = Mathf.Clamp(orbitalPitch, -85f, 85f);
        }

        // Scroll zoom
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distance -= scroll * 5f;
        distance = Mathf.Clamp(distance, 2f, 20f);

        float radYaw = orbitalYaw * Mathf.Deg2Rad;
        float radPitch = orbitalPitch * Mathf.Deg2Rad;

        Vector3 direction = new Vector3(
            Mathf.Sin(radYaw) * Mathf.Cos(radPitch),
            Mathf.Sin(radPitch),
            Mathf.Cos(radYaw) * Mathf.Cos(radPitch)
        );

        Vector3 offset = direction * distance;
        transform.position = targets[currentTargetIndex].position + offset;
        transform.LookAt(targets[currentTargetIndex]);
    }
}