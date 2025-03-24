using CSV
using DSP
using JSON
using DataFrames
using ArgParse

const fs = 250  # Define sampling frequency

# Notch filters
const notch_0 = iirnotch(4, 8; fs=fs)
const notch_60 = iirnotch(60, 30; fs=fs)

const bandstop = digitalfilter(Bandstop(1 / (fs / 2), 5 / (fs / 2)), Butterworth(8))
const bandpass = digitalfilter(Bandpass(4 / (fs / 2), 32 / (fs / 2)), Butterworth(4))

function teste_load_data()

    parser = ArgParse.ArgParser()
    add_argument(parser, "--csv", help="Caminho do arquivo CSV", required=true)
    args = parse_args(parser)
    println("Caminho do CSV: ", args["csv"])
    data = CSV.read(args["csv"], DataFrame; delim=",")
    # data = CSV.read("dados.csv", DataFrame; delim=",")

    markers = []
    for i in eachindex(data[:, 10])
        if (!ismissing(data[i, 10]))
            push!(markers, i)
        end
    end

    data = DataFrame(
        "Time" => data[markers[2]:end, 1],
        "Ch1" => data[markers[2]:end, 2],
        "Ch2" => data[markers[2]:end, 3],
        "Ch3" => data[markers[2]:end, 4],
        "Ch4" => data[markers[2]:end, 5],
        "Ch5" => data[markers[2]:end, 6],
        "Ch6" => data[markers[2]:end, 7],
        "Ch7" => data[markers[2]:end, 8],
        "Ch8" => data[markers[2]:end, 9]
    )
    
    # Adjust the time to start from zero
    data[!, 1] .= data[!, 1] .- data[1, 1]
    
    # Adjust markers
    markers = markers[2:end]
    markers .= markers .- (markers[1] - 1)
    
    # Apply filters to each channel
    for channel = 2:9
        data[!, channel] .= filt(bandstop, data[!, channel])
        data[!, channel] .= filt(notch_60, data[!, channel])
        data[!, channel] .= filt(bandpass, data[!, channel])
    
        # Zero out values if they exceed the threshold
        for v in eachindex(data[!, channel])
            if abs(data[v, channel]) > 60
                data[v, channel] = 0.0
            end
        end
    
        # Apply filters again
        data[!, channel] .= filt(bandstop, data[!, channel])
        data[!, channel] .= filt(notch_0, data[!, channel])
    end
    
    # Convert each column to a string representing an array (as required)
    time_column = "[" * join(string.(data[!, 1]), ", ") * "]"
    channels = [ "[" * join(string.(data[!, channel]), ", ") * "]" for channel in 2:9 ]

    formatted_data = DataFrame("Time" => [time_column],
                               "Ch1" => [channels[1]],
                               "Ch2" => [channels[2]],
                               "Ch3" => [channels[3]],
                               "Ch4" => [channels[4]],
                               "Ch5" => [channels[5]],
                               "Ch6" => [channels[6]],
                               "Ch7" => [channels[7]],
                               "Ch8" => [channels[8]])

    return formatted_data
end

# Load and process data
teste_data = teste_load_data()

CSV.write("saida2.csv", teste_data)
print("carregou")
