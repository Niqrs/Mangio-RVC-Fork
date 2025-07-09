# Заглушка для parselmouth когда он недоступен
import warnings

warnings.warn(
    "Parselmouth is not available. Some F0 methods will not work.", ImportWarning
)


class Sound:
    def __init__(self, *args, **kwargs):
        raise NotImplementedError(
            "Parselmouth is not installed. Cannot use parselmouth-based F0 methods."
        )

    def to_pitch(self, *args, **kwargs):
        raise NotImplementedError(
            "Parselmouth is not installed. Cannot use parselmouth-based F0 methods."
        )


# Минимальная совместимость
__version__ = "0.0.0-mock"
