#####
##### Testing distributed self-play
#####

ENV["JULIA_CUDA_MEMORY_POOL"] = "split"

using AlphaZero
using ProgressMeter

using Knet
Knet.conv4_algo(w::KnetArray{T}, x::KnetArray{T}, y::KnetArray{T}; handle=Knet.cudnnhandle(), o...) where {T} = (0,0)
Knet.conv4w_algo(w::KnetArray{T},x::KnetArray{T},dy::KnetArray{T},dw::KnetArray{T}; handle=Knet.cudnnhandle(), o...) where {T} = (0,0)
Knet.conv4x_algo(w::KnetArray{T},x::KnetArray{T},dy::KnetArray{T},dx::KnetArray{T}; handle=Knet.cudnnhandle(), o...) where {T} = (0,0)

include("../games.jl")
GAME = get(ENV, "GAME", "connect-four")
SelectedGame = GAME_MODULE[GAME]
using .SelectedGame: Game, Training

const params = Training.params
network = Training.Network{Game}(Training.netparams)
env = AlphaZero.Env{Game}(params, network)

const progress = Progress(params.self_play.num_games)

struct Handler end
AlphaZero.Handlers.game_played(::Handler) = next!(progress)

println("Running on $(Threads.nthreads()) threads.")

report = AlphaZero.self_play_step!(env, Handler())
