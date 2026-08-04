package main

type ApiError struct {
	Msg    string
	Status int
}

func (e *ApiError) Error() string {
	return e.Msg
}
