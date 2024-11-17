#
#
using CSV
using DSP
using JSON
using DataFrames

const notch_0 = iirnotch(4, 8; fs=250)
const notch_60 = iirnotch(60, 30; fs=250)
const bandstop = digitalfilter(Bandstop(1, 5; fs=250), Butterworth(8))
const bandpass = digitalfilter(Bandpass(4, 32; fs=250), Butterworth(4))

function teste_load_data()
    data = CSV.read("dados.csv", DataFrame; delim=",")

    markers = []

    for i in eachindex(data[:, 10])
        if (!ismissing(data[i, 10]))
            push!(markers, i)
        end
    end

    data = DataFrame("Time" => data[markers[2]:end, 1],
        "Ch1" => data[markers[2]:end, 2],
        "Ch2" => data[markers[2]:end, 3],
        "Ch3" => data[markers[2]:end, 4],
        "Ch4" => data[markers[2]:end, 5],
        "Ch5" => data[markers[2]:end, 6],
        "Ch6" => data[markers[2]:end, 7],
        "Ch7" => data[markers[2]:end, 8],
        "Ch8" => data[markers[2]:end, 9])

    data[!, 1] .= data[!, 1] .- data[1, 1]
    markers = markers[2:end]
    markers .= markers .- (markers[1] - 1)

    for channel = 2:9
        data[!, channel] .= filt(bandstop, data[!, channel])
        data[!, channel] .= filt(notch_60, data[!, channel])
        data[!, channel] .= filt(bandpass, data[!, channel])

        for v in eachindex(data[!, channel])
            if (abs(data[v, channel]) > 60)
                data[v, channel] = 0.0
            end
        end

        data[!, channel] .= filt(bandstop, data[!, channel])
        data[!, channel] .= filt(notch_0, data[!, channel])
    end

    return data[!, 1:9], markers
end

teste_data = teste_load_data()
json_data = JSON.json(teste_data[1])

## --
open("dataset.json", "w") do f
    write(f, json_data)
end
## --


#https://discourse.julialang.org/