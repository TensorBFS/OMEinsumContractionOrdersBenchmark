import pickle, json
import os

def convert_instance_to_json(instance_name):
    """Convert a pickle instance to JSON format suitable for OMEinsum.
    
    Args:
        instance_name (str): Name of the instance file (without .pkl extension)
        
    Returns:
        dict: Dictionary containing einsum and size information
    """
    input_file = os.path.join(os.path.dirname(__file__), "instances", f"{instance_name}.pkl")
    
    with open(input_file, "rb") as f:
        string, tensors, *rest = pickle.load(f)

    ixs = []
    iy = []
    size = {}
    char_to_int = {}

    ixs_string, iy_string = string.split("->")

    for ix_string, tensor in zip(ixs_string.split(","), tensors):
        ix = []
        
        for c, n in zip(ix_string, tensor.shape):
            if c not in char_to_int:
                char_to_int[c] = len(char_to_int) + 1
            
            i = char_to_int[c]
            size[str(i)] = n
            ix.append(i)
        
        ixs.append(ix)
        
    for c in iy_string:
        i = char_to_int[c]
        iy.append(i)
        
    return {
        "einsum": {
            "ixs": ixs,
            "iy": iy,
        },
        "size": size,
    }

def save_instance_as_json(instance_name, output_dir=None):
    """Convert an instance to JSON and save it to a file.
    
    Args:
        instance_name (str): Name of the instance file (without .pkl extension)
        output_dir (str, optional): Output directory. Defaults to 'codes' subdirectory.
    """
    if output_dir is None:
        output_dir = os.path.join(os.path.dirname(__file__), "codes")
    
    output_file = os.path.join(output_dir, f"{instance_name}.json")
    
    result = convert_instance_to_json(instance_name)
    
    with open(output_file, "w") as f:
        json.dump(result, f, indent=2)
    
    print(f"Converted {instance_name} to {output_file}")

# Main execution - convert the default instance
if __name__ == "__main__":
    name = "qc_qft_27"
    save_instance_as_json(name)