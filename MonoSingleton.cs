namespace UnityEngine
{
    /// <summary>
    /// This class creates it's own instance if not assigned to an existing gameobject
    /// </summary>
    public abstract class MonoSingleton<tt> : MonoBehaviour where tt : Component
    {
        static tt _instance;
        public static tt Instance => _instance ?? SetInstance(new GameObject(typeof(tt).Name).AddComponent<tt>());

        static tt SetInstance(tt instance)
        {
            if (_instance != instance)
                DontDestroyOnLoad(_instance = instance);
            return _instance;
        }

        protected virtual void Awake()
        {
            if (_instance == null)
                SetInstance(this as tt ?? throw new System.InvalidCastException(typeof(tt).Name));
            if (_instance != this)
                Destroy(this.gameObject);
        }
    }
}
