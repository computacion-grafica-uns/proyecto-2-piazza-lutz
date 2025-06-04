using UnityEngine;
using UnityEngine.SceneManagement; // Necesario para la gesti�n de escenas

public class CambioEscenas : MonoBehaviour
{
    [SerializeField] private string escenaInicial = "Escena A";
    [SerializeField] private string escenaAlternativa = "Escena B";

    void Start()
    {
        SceneManager.LoadScene(escenaInicial);
    }

    void Update()
    {
        /*if (Input.GetKeyDown(KeyCode.L))
        {
            string currentSceneName = SceneManager.GetActiveScene().name;
            if (currentSceneName == escenaInicial)
            {
                SceneManager.LoadScene(escenaAlternativa);
            }
            else
            {
                SceneManager.LoadScene(escenaInicial);
            }
        }*/
    }
}